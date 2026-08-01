"""Reference implementation of the tracker contract.

This is a **test fixture**, not a shippable plugin: it records watch state in its
own tables instead of syncing anywhere, so the host's dispatch, normalisation,
enrichment, caching and settings plumbing can all be exercised without a network
or an account.

It doubles as the worked example for writing a real tracker.  Note what is
*absent*: no OAuth code (the host runs the device flow), no HTTP retry logic (the
client handles it), no schema migration code (declared in ``plugin.json``), and
no imports from ``warp_mediacenter`` — a plugin only ever sees the ``context``
bundle it is handed.
"""

from __future__ import annotations

import time
from typing import Any, Dict, Optional

CONFIG_TABLE = "plugin_fake_tracker_config"
WATCH_TABLE = "plugin_fake_tracker_watch"

#: Below this, an item is still "in progress"; at or above it, it is finished and
#: drops out of Continue Watching.  Mirrors the convention trackers use.
COMPLETION_THRESHOLD = 90.0

DEFAULTS = {
    "completion_threshold": str(COMPLETION_THRESHOLD),
    "display_name": "Fake Tracker",
}


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------


def _ok(**data: Any) -> Dict[str, Any]:
    return {"ok": True, "data": data}


def _err(code: str, message: str, **details: Any) -> Dict[str, Any]:
    return {
        "ok": False,
        "error": {"code": code, "message": message, "details": details},
    }


def _config(ctx) -> Dict[str, str]:
    rows = ctx["db"].query(f"SELECT k, v FROM {CONFIG_TABLE}")
    values = dict(DEFAULTS)
    values.update({row["k"]: row["v"] for row in rows})
    return values


def _set_config(ctx, key: str, value: Any) -> None:
    ctx["db"].execute(
        f"INSERT INTO {CONFIG_TABLE} (k, v) VALUES (?, ?) "
        "ON CONFLICT(k) DO UPDATE SET v = excluded.v",
        (key, "" if value is None else str(value)),
    )


def _threshold(ctx) -> float:
    try:
        return float(_config(ctx).get("completion_threshold", COMPLETION_THRESHOLD))
    except (TypeError, ValueError):
        return COMPLETION_THRESHOLD


def _media_key(media: Dict[str, Any]) -> Optional[str]:
    """The tmdb id this item is filed under.

    Episodes are keyed by their *show* — Continue Watching is a list of shows the
    user is part-way through, not of individual episodes.
    """

    if media.get("type") == "episode":
        ids = (media.get("show") or {}).get("ids") or {}
    else:
        ids = media.get("ids") or {}
    tmdb = ids.get("tmdb")
    return str(tmdb) if tmdb is not None else None


# ---------------------------------------------------------------------------
# actions
# ---------------------------------------------------------------------------


def _install(ctx) -> Dict[str, Any]:
    for key, value in DEFAULTS.items():
        _set_config(ctx, key, value)
    ctx["log"].info("fake_tracker_installed")
    return _ok(seeded=list(DEFAULTS))


def _describe(ctx) -> Dict[str, Any]:
    return _ok(
        service="fake-tracker",
        display_name=_config(ctx).get("display_name"),
        auth_kind="device_code",
    )


def _scrobble(ctx, payload: Dict[str, Any], action: str) -> Dict[str, Any]:
    media = payload.get("media") or {}
    key = _media_key(media)
    if not key:
        return _err("invalid_request", "media has no tmdb id")

    progress = float(payload.get("progress") or 0.0)
    media_type = "show" if media.get("type") == "episode" else "movie"
    title = media.get("title") or (media.get("show") or {}).get("title") or ""

    ctx["db"].execute(
        f"INSERT INTO {WATCH_TABLE} "
        "(tmdb_id, media_type, title, progress, season, episode, updated_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?) "
        "ON CONFLICT(tmdb_id) DO UPDATE SET "
        "media_type=excluded.media_type, title=excluded.title, "
        "progress=excluded.progress, season=excluded.season, "
        "episode=excluded.episode, updated_at=excluded.updated_at",
        (
            key,
            media_type,
            title,
            progress,
            media.get("season"),
            media.get("episode"),
            ctx["now"](),
        ),
    )
    ctx["log"].info("fake_scrobble", action=action, tmdb_id=key, progress=progress)
    return _ok(action=action, tmdb_id=key, progress=progress)


def _continue_watching(ctx, payload: Dict[str, Any]) -> Dict[str, Any]:
    media_type = str(payload.get("media_type") or "movie")
    limit = int(payload.get("limit") or 20)
    threshold = _threshold(ctx)

    rows = ctx["db"].query(
        f"SELECT * FROM {WATCH_TABLE} WHERE media_type = ? AND progress > 0 "
        "AND progress < ? ORDER BY updated_at DESC LIMIT ?",
        (media_type, threshold, limit),
    )

    items = []
    for row in rows:
        tmdb_id = int(row["tmdb_id"])
        if media_type == "movie":
            media = {"type": "movie", "ids": {"tmdb": tmdb_id}, "title": row["title"]}
        else:
            media = {"type": "show", "ids": {"tmdb": tmdb_id}, "title": row["title"]}
        items.append(
            {
                "media": media,
                "progress": float(row["progress"]),
                "resume_available": True,
                "playback_id": row["tmdb_id"],
                "resume_season": row["season"],
                "resume_episode": row["episode"],
                "is_scrobbled": True,
                "sort_key": float(row["updated_at"]),
            }
        )

    return _ok(items=items, count=len(items))


def _item_progress(ctx, payload: Dict[str, Any]) -> Dict[str, Any]:
    media = payload.get("media") or {}
    key = _media_key(media)
    if not key:
        return _err("invalid_request", "media has no tmdb id")

    row = ctx["db"].query_one(
        f"SELECT * FROM {WATCH_TABLE} WHERE tmdb_id = ?", (key,)
    )
    threshold = _threshold(ctx)

    if media.get("type") == "movie":
        if not row:
            return _ok(type="movie", progress=0.0, resume_available=False, watched=False)
        progress = float(row["progress"])
        return _ok(
            type="movie",
            progress=progress,
            resume_available=0 < progress < threshold,
            playback_id=row["tmdb_id"],
            watched=progress >= threshold,
        )

    if not row:
        return _err("not_found", f"No progress recorded for show {key}")

    season = row["season"] or 1
    episode = row["episode"] or 1
    progress = float(row["progress"])
    return _ok(
        type="show",
        trakt_id=None,
        aired=episode,
        completed=max(0, episode - 1),
        seasons=[
            {
                "number": season,
                "aired": episode,
                "completed": max(0, episode - 1),
                "episodes": [
                    {
                        "number": n,
                        "completed": n < episode,
                        "last_watched_at": None,
                        "scrobble_progress": progress if n == episode else None,
                        "playback_id": row["tmdb_id"] if n == episode else None,
                    }
                    for n in range(1, episode + 1)
                ],
            }
        ],
    )


def _mark_watched(ctx, payload: Dict[str, Any]) -> Dict[str, Any]:
    media = payload.get("media") or {}
    key = _media_key(media)
    if not key:
        return _err("invalid_request", "media has no tmdb id")
    ctx["db"].execute(
        f"UPDATE {WATCH_TABLE} SET progress = 100.0, updated_at = ? WHERE tmdb_id = ?",
        (ctx["now"](), key),
    )
    return _ok(synced=True, tmdb_id=key)


def _remove(ctx, payload: Dict[str, Any]) -> Dict[str, Any]:
    media = payload.get("media") or {}
    key = str(payload.get("playback_id") or _media_key(media) or "")
    if not key:
        return _err("invalid_request", "no playback_id or tmdb id")
    removed = ctx["db"].execute(
        f"DELETE FROM {WATCH_TABLE} WHERE tmdb_id = ?", (key,)
    )
    return _ok(removed=removed > 0)


def _settings_schema(ctx) -> Dict[str, Any]:
    config = _config(ctx)
    watched = ctx["db"].query_one(f"SELECT COUNT(*) AS n FROM {WATCH_TABLE}") or {}
    return _ok(
        sections=[
            {
                "id": "account",
                "title": "Account",
                "fields": [
                    {
                        "type": "auth_panel",
                        "id": "auth",
                        "label": "Fake Tracker",
                        "help": "This fixture never contacts a real service.",
                    }
                ],
            },
            {
                "id": "behaviour",
                "title": "Behaviour",
                "fields": [
                    {
                        "type": "text",
                        "id": "display_name",
                        "label": "Display name",
                        "value": config.get("display_name", ""),
                    },
                    {
                        "type": "number",
                        "id": "completion_threshold",
                        "label": "Completion threshold (%)",
                        "value": float(config.get("completion_threshold", 90)),
                        "min": 50,
                        "max": 100,
                        "help": "Items at or above this drop out of Continue Watching.",
                    },
                    {
                        "type": "action_button",
                        "id": "reset",
                        "label": "Clear recorded watch state",
                        "style": "danger",
                        "confirm": True,
                    },
                    {
                        "type": "info",
                        "id": "stats",
                        "text": f"{watched.get('n', 0)} item(s) recorded.",
                    },
                ],
            },
        ]
    )


def _settings_save(ctx, payload: Dict[str, Any]) -> Dict[str, Any]:
    values = payload.get("values") or {}
    saved = []
    for key in ("display_name", "completion_threshold"):
        if key not in values:
            continue
        value = values[key]
        if key == "completion_threshold":
            try:
                value = max(50.0, min(100.0, float(value)))
            except (TypeError, ValueError):
                return _err("invalid_request", "completion_threshold must be a number")
        _set_config(ctx, key, value)
        saved.append(key)
    return _ok(saved=saved)


# ---------------------------------------------------------------------------
# entrypoint
# ---------------------------------------------------------------------------


def handle(action: str, payload: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
    ctx = context
    payload = payload or {}

    if action == "plugin.install":
        return _install(ctx)
    if action in ("plugin.uninstall", "plugin.enable", "plugin.disable"):
        return _ok(acknowledged=action)
    if action == "plugin.settings.schema":
        return _settings_schema(ctx)
    if action == "plugin.settings.save":
        return _settings_save(ctx, payload)
    if action == "plugin.action.reset":
        ctx["db"].execute(f"DELETE FROM {WATCH_TABLE}")
        return _ok(cleared=True)

    if action == "tracker.describe":
        return _describe(ctx)
    if action == "tracker.scrobble.start":
        return _scrobble(ctx, payload, "start")
    if action == "tracker.scrobble.stop":
        return _scrobble(ctx, payload, "stop")
    if action == "tracker.continue_watching":
        return _continue_watching(ctx, payload)
    if action == "tracker.item_progress":
        return _item_progress(ctx, payload)
    if action == "tracker.mark_watched":
        return _mark_watched(ctx, payload)
    if action == "tracker.remove_from_continue_watching":
        return _remove(ctx, payload)
    if action == "tracker.account":
        return _ok(account={"id": "fixture", "username": "fixture-user"})
    if action == "tracker.cache.clear":
        ctx["cache"].clear()
        return _ok(cleared=True)

    return _err("unsupported_action", f"Unknown action '{action}'")
