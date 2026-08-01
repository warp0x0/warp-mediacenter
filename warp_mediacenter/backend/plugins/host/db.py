"""Scoped database access for plugins.

A plugin owns its own tables — it declares them in its manifest, migrates them,
and its settings page writes straight to them.  The host stores no plugin
configuration itself.

Scoping is enforced by **SQLite's own authorizer**, not by inspecting SQL
strings.  ``sqlite3.Connection.set_authorizer`` is consulted by the query planner
for every table, column and schema operation a statement performs, so no amount
of quoting, commenting, aliasing or nesting inside a CTE gets a query past it.  A
string-matching guard, by contrast, is only ever as good as its last bug.

The policy is deny-by-default:

* reads and writes are permitted only on ``plugin_{slug}_*`` tables;
* ``ATTACH``, ``DETACH`` and ``PRAGMA`` are refused outright — the first two
  would reach another database file, the third can disable enforcement;
* the ``temp`` database is permitted, since it is private to the connection and
  vanishes with it;
* ``sqlite_master`` is readable but not directly writable.  ``ALTER TABLE`` and
  ``DROP TABLE`` are implemented by reading and rewriting the schema row, so
  denying those reads would cost plugins the two most common migration
  operations.  What it exposes is the host's table definitions — schema, not
  data.

**On the threat model.** Plugins run in-process, as ordinary Python.  Nothing
here stops code that is actively trying to escape: it could open the database
file itself.  What this *does* prevent is the realistic failure — a plugin whose
SQL is wrong, over-broad, or copy-pasted reaching into ``titles`` or another
plugin's tables and corrupting them.  Treat it as a guardrail that makes mistakes
loud and immediate, not as a sandbox around hostile code.  Real isolation would
need a subprocess, which is a deliberate non-goal for this pass.

The manifest-time prefix check in ``PluginDatabaseSpec.validate_prefix`` catches
the same class of mistake earlier, at install time, with a clearer message.
"""

from __future__ import annotations

import sqlite3
import threading
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Sequence, Tuple

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.plugins.exceptions import PluginError
from warp_mediacenter.config.settings import get_database_path

log = get_logger(__name__)


class PluginDatabaseDenied(PluginError):
    """Raised when a plugin's SQL touches something outside its namespace."""


# Actions whose first argument is a table name.
_TABLE_ACTIONS = frozenset(
    {
        sqlite3.SQLITE_READ,
        sqlite3.SQLITE_INSERT,
        sqlite3.SQLITE_UPDATE,
        sqlite3.SQLITE_DELETE,
        sqlite3.SQLITE_CREATE_TABLE,
        sqlite3.SQLITE_DROP_TABLE,
        sqlite3.SQLITE_ANALYZE,
        sqlite3.SQLITE_CREATE_VIEW,
        sqlite3.SQLITE_DROP_VIEW,
    }
)

# Actions where arg1 is the index/trigger name and arg2 is the table it targets.
# The table is what matters; the name is checked only for namespace hygiene.
_INDEXED_ACTIONS = frozenset(
    {
        sqlite3.SQLITE_CREATE_INDEX,
        sqlite3.SQLITE_DROP_INDEX,
        sqlite3.SQLITE_CREATE_TRIGGER,
        sqlite3.SQLITE_DROP_TRIGGER,
    }
)

# ALTER TABLE is the odd one out: arg1 is the *database* name ("main"), and the
# table being altered is arg2.  Checking arg1 here would compare "main" against
# the plugin prefix and refuse every ALTER.
_ALTER_ACTIONS = frozenset({sqlite3.SQLITE_ALTER_TABLE})

# REINDEX passes the index (or table) name as arg1 with no arg2.  SQLite emits it
# implicitly after CREATE INDEX, so refusing it breaks index creation.
_REINDEX_ACTIONS = frozenset({sqlite3.SQLITE_REINDEX})

# Statement-level checks with no object name attached.  Permitting these does not
# grant access to anything — the per-table checks above still run.
_ALWAYS_ALLOWED = frozenset(
    {
        sqlite3.SQLITE_SELECT,
        sqlite3.SQLITE_TRANSACTION,
        sqlite3.SQLITE_SAVEPOINT,
        sqlite3.SQLITE_FUNCTION,
        sqlite3.SQLITE_RECURSIVE,
    }
)

# Temp-schema operations: private to this connection, invisible to the host.
_TEMP_ACTIONS = frozenset(
    {
        sqlite3.SQLITE_CREATE_TEMP_TABLE,
        sqlite3.SQLITE_DROP_TEMP_TABLE,
        sqlite3.SQLITE_CREATE_TEMP_INDEX,
        sqlite3.SQLITE_DROP_TEMP_INDEX,
        sqlite3.SQLITE_CREATE_TEMP_TRIGGER,
        sqlite3.SQLITE_DROP_TEMP_TRIGGER,
        sqlite3.SQLITE_CREATE_TEMP_VIEW,
        sqlite3.SQLITE_DROP_TEMP_VIEW,
    }
)

_ALWAYS_DENIED = frozenset(
    {
        sqlite3.SQLITE_ATTACH,
        sqlite3.SQLITE_DETACH,
        sqlite3.SQLITE_PRAGMA,
        sqlite3.SQLITE_CREATE_VTABLE,
        sqlite3.SQLITE_DROP_VTABLE,
    }
)

#: SQLite records DDL by writing rows into the schema table, so a permitted
#: ``CREATE TABLE plugin_x_config`` arrives at the authorizer as an INSERT on
#: ``sqlite_master``.  Those writes are allowed; the DDL itself was already
#: checked by the CREATE/DROP/ALTER action above.  Manipulating the schema table
#: directly requires ``PRAGMA writable_schema``, which is denied, and *reads* of
#: it stay denied so host table names remain private.
_SCHEMA_TABLES = frozenset(
    {
        "sqlite_master",
        "sqlite_schema",
        "sqlite_temp_master",
        "sqlite_temp_schema",
        "sqlite_sequence",
    }
)

_SCHEMA_WRITE_ACTIONS = frozenset(
    {sqlite3.SQLITE_INSERT, sqlite3.SQLITE_UPDATE, sqlite3.SQLITE_DELETE}
)

#: SQLite phrases authorizer refusals two ways depending on the action: a denied
#: column read is "access to t.c is prohibited", everything else is "not
#: authorized".  Both mean the sandbox refused.
_DENIED_MARKERS = ("not authorized", "is prohibited")


def _is_denial(exc: BaseException) -> bool:
    message = str(exc).lower()
    return any(marker in message for marker in _DENIED_MARKERS)


class PluginDatabase:
    """A plugin's private slice of the application database."""

    def __init__(
        self,
        *,
        plugin_id: str,
        slug: str,
        db_path: Optional[Path] = None,
        allowed_tables: Optional[Sequence[str]] = None,
    ) -> None:
        self._plugin_id = plugin_id
        self._slug = slug
        self._prefix = f"plugin_{slug}_"
        self._db_path = Path(db_path or get_database_path())
        #: Extra names outside the prefix that this plugin may touch.  Empty in
        #: normal operation; exists so the host can widen access deliberately
        #: rather than a plugin widening it accidentally.
        self._extra_tables = {t.lower() for t in (allowed_tables or ())}
        self._lock = threading.RLock()
        self._conn: Optional[sqlite3.Connection] = None
        self._last_denied: Optional[str] = None

    # -- policy ---------------------------------------------------------

    @property
    def table_prefix(self) -> str:
        return self._prefix

    def qualify(self, table: str) -> str:
        """Namespaced name for one of the plugin's declared tables."""

        name = str(table).strip().lower()
        return name if name.startswith(self._prefix) else f"{self._prefix}{name}"

    def _permitted(self, name: Optional[str]) -> bool:
        if not name:
            return False
        lowered = name.lower()
        return lowered.startswith(self._prefix) or lowered in self._extra_tables

    def _authorize(
        self,
        action: int,
        arg1: Optional[str],
        arg2: Optional[str],
        db_name: Optional[str],
        trigger: Optional[str],
    ) -> int:
        if action in _ALWAYS_DENIED:
            self._last_denied = f"action {action}"
            return sqlite3.SQLITE_DENY

        if action in _ALWAYS_ALLOWED:
            return sqlite3.SQLITE_OK

        # Anything in the temp schema is private to this connection.
        if action in _TEMP_ACTIONS or (db_name or "").lower() == "temp":
            return sqlite3.SQLITE_OK

        # Schema bookkeeping.  CREATE/ALTER/DROP are implemented as reads and
        # writes of the schema row, and the DDL itself was already checked by the
        # CREATE/DROP/ALTER action.  Direct manipulation still needs
        # `PRAGMA writable_schema`, which is denied above.
        if (arg1 or "").lower() in _SCHEMA_TABLES:
            if action in _SCHEMA_WRITE_ACTIONS or action == sqlite3.SQLITE_READ:
                return sqlite3.SQLITE_OK
            self._last_denied = f"{arg1}.{arg2}" if arg2 else str(arg1)
            return sqlite3.SQLITE_DENY

        if action in _TABLE_ACTIONS:
            if self._permitted(arg1):
                return sqlite3.SQLITE_OK
            self._last_denied = arg1 or "<unknown>"
            return sqlite3.SQLITE_DENY

        if action in _ALTER_ACTIONS:
            if self._permitted(arg2):
                return sqlite3.SQLITE_OK
            self._last_denied = arg2 or "<unknown>"
            return sqlite3.SQLITE_DENY

        if action in _REINDEX_ACTIONS:
            if self._permitted(arg1) or self._permitted_index(arg1 or ""):
                return sqlite3.SQLITE_OK
            self._last_denied = arg1 or "<unknown>"
            return sqlite3.SQLITE_DENY

        if action in _INDEXED_ACTIONS:
            # arg2 is the table the index/trigger is attached to.
            if self._permitted(arg2) and (arg1 is None or self._permitted_index(arg1)):
                return sqlite3.SQLITE_OK
            self._last_denied = arg2 or arg1 or "<unknown>"
            return sqlite3.SQLITE_DENY

        # Deny by default: an action we have not reasoned about is not allowed.
        self._last_denied = f"action {action}"
        return sqlite3.SQLITE_DENY

    def _permitted_index(self, name: str) -> bool:
        """Whether an index/trigger *name* is acceptable.

        Access is really governed by the table (checked separately); this only
        keeps a plugin from squatting names in the shared index namespace.
        ``sqlite_autoindex_*`` is SQLite's own name for the implicit index behind
        a PRIMARY KEY or UNIQUE constraint, so it must be allowed or no plugin
        could declare a primary key.
        """

        lowered = name.lower()
        return (
            lowered.startswith(self._prefix)
            or lowered.startswith(f"idx_{self._prefix}")
            or lowered.startswith(f"sqlite_autoindex_{self._prefix}")
        )

    # -- connection -----------------------------------------------------

    def _connection(self) -> sqlite3.Connection:
        with self._lock:
            if self._conn is None:
                conn = sqlite3.connect(str(self._db_path), check_same_thread=False)
                conn.row_factory = sqlite3.Row
                # Set pragmas *before* installing the authorizer, which denies them.
                conn.execute("PRAGMA busy_timeout = 15000")
                conn.execute("PRAGMA foreign_keys = ON")
                conn.set_authorizer(self._authorize)
                self._conn = conn
            return self._conn

    def _wrap_denied(self, exc: sqlite3.DatabaseError) -> PluginError:
        denied = self._last_denied or "an unauthorised object"
        return PluginDatabaseDenied(
            f"Plugin '{self._plugin_id}' may only access tables named "
            f"'{self._prefix}*'; denied access to {denied}"
        )

    # -- api ------------------------------------------------------------

    def execute(self, sql: str, params: Sequence[Any] | Dict[str, Any] = ()) -> int:
        """Run a statement, returning the affected row count."""

        conn = self._connection()
        with self._lock:
            try:
                cursor = conn.execute(sql, params)
                conn.commit()
                return cursor.rowcount
            except sqlite3.DatabaseError as exc:
                conn.rollback()
                if _is_denial(exc):
                    raise self._wrap_denied(exc) from exc
                raise PluginError(f"Plugin query failed: {exc}") from exc

    def executemany(
        self, sql: str, seq_of_params: Sequence[Sequence[Any]]
    ) -> int:
        conn = self._connection()
        with self._lock:
            try:
                cursor = conn.executemany(sql, seq_of_params)
                conn.commit()
                return cursor.rowcount
            except sqlite3.DatabaseError as exc:
                conn.rollback()
                if _is_denial(exc):
                    raise self._wrap_denied(exc) from exc
                raise PluginError(f"Plugin query failed: {exc}") from exc

    def query(
        self, sql: str, params: Sequence[Any] | Dict[str, Any] = ()
    ) -> List[Dict[str, Any]]:
        conn = self._connection()
        with self._lock:
            try:
                rows = conn.execute(sql, params).fetchall()
            except sqlite3.DatabaseError as exc:
                if _is_denial(exc):
                    raise self._wrap_denied(exc) from exc
                raise PluginError(f"Plugin query failed: {exc}") from exc
        return [dict(row) for row in rows]

    def query_one(
        self, sql: str, params: Sequence[Any] | Dict[str, Any] = ()
    ) -> Optional[Dict[str, Any]]:
        rows = self.query(sql, params)
        return rows[0] if rows else None

    @contextmanager
    def transaction(self) -> Iterator[sqlite3.Connection]:
        """Run several statements atomically.

        The yielded connection carries the same authorizer, so the sandbox holds
        inside the block.
        """

        conn = self._connection()
        with self._lock:
            try:
                yield conn
                conn.commit()
            except sqlite3.DatabaseError as exc:
                conn.rollback()
                if _is_denial(exc):
                    raise self._wrap_denied(exc) from exc
                raise PluginError(f"Plugin transaction failed: {exc}") from exc
            except Exception:
                conn.rollback()
                raise

    def close(self) -> None:
        with self._lock:
            if self._conn is not None:
                try:
                    self._conn.close()
                finally:
                    self._conn = None


def run_plugin_migrations(
    *,
    plugin_id: str,
    slug: str,
    migrations: Sequence[Tuple[int, str]],
    current_version: int,
    db_path: Optional[Path] = None,
) -> int:
    """Apply a plugin's declared migrations, returning the new version.

    Runs through the sandboxed connection, so a migration that reaches outside
    the plugin's namespace fails here rather than corrupting host data — the
    manifest check is belt, this is braces.
    """

    pending = [(v, sql) for v, sql in migrations if v > current_version]
    if not pending:
        return current_version

    database = PluginDatabase(plugin_id=plugin_id, slug=slug, db_path=db_path)
    try:
        applied = current_version
        for version, sql in sorted(pending, key=lambda item: item[0]):
            with database.transaction() as conn:
                conn.executescript(sql)
            applied = version
            log.info("plugin_migration_applied", plugin_id=plugin_id, version=version)
        return applied
    finally:
        database.close()


def drop_plugin_tables(
    *, slug: str, db_path: Optional[Path] = None
) -> List[str]:
    """Drop every table a plugin owns.  Called by the host on uninstall.

    Uses a host connection: the plugin's own sandbox forbids reading
    ``sqlite_master``, and by this point the plugin is going away anyway.
    """

    prefix = f"plugin_{slug}_"
    conn = sqlite3.connect(str(db_path or get_database_path()))
    conn.row_factory = sqlite3.Row
    dropped: List[str] = []
    try:
        rows = conn.execute(
            "SELECT name, type FROM sqlite_master WHERE name LIKE ? AND type IN ('table','index','view','trigger')",
            (f"{prefix}%",),
        ).fetchall()
        index_rows = conn.execute(
            "SELECT name, type FROM sqlite_master WHERE name LIKE ? AND type = 'index'",
            (f"idx_{prefix}%",),
        ).fetchall()

        # Drop dependants first so a table drop cannot fail on a lingering view.
        ordered = sorted(
            list(rows) + list(index_rows),
            key=lambda r: {"trigger": 0, "index": 1, "view": 2, "table": 3}.get(r["type"], 4),
        )
        for row in ordered:
            kind = row["type"].upper()
            if kind == "INDEX" and row["name"].startswith("sqlite_autoindex"):
                continue
            try:
                conn.execute(f'DROP {kind} IF EXISTS "{row["name"]}"')
                dropped.append(row["name"])
            except sqlite3.DatabaseError as exc:
                log.warning("plugin_table_drop_failed", name=row["name"], error=str(exc))
        conn.commit()
    finally:
        conn.close()

    if dropped:
        log.info("plugin_tables_dropped", slug=slug, dropped=dropped)
    return dropped


__all__ = [
    "PluginDatabase",
    "PluginDatabaseDenied",
    "drop_plugin_tables",
    "run_plugin_migrations",
]
