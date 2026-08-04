"""Plugin management API.

Backs the Settings → Plugins screen: list what is installed by category, install
from a file the user picked, toggle plugins on and off, and render each plugin's
own settings page.

Plugin configuration is *not* stored here.  ``GET /{id}/settings-schema`` asks the
plugin to describe its settings including current values, and ``PUT
/{id}/settings`` hands submitted values back for the plugin to persist in its own
tables.  The host contributes only what the plugin cannot know: whether it is the
active one, and the state of the OAuth session the host runs on its behalf.
"""

from __future__ import annotations

import asyncio
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.parse import urlsplit

import requests
from fastapi import APIRouter, Body, HTTPException, Query

from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.plugins.contracts.common import (
    PLUGIN_CATEGORIES,
    ERROR_HTTP_STATUS,
    ErrorCode,
    error_code,
    get_category,
    is_ok,
    response_data,
)
from warp_mediacenter.backend.plugins.contracts.lifecycle import LifecycleAction
from warp_mediacenter.backend.plugins.exceptions import PluginError
from warp_mediacenter.backend.plugins.manager import PluginManager
from warp_mediacenter.backend.plugins.registry import PluginRecord, PluginRegistry

log = get_logger(__name__)

router = APIRouter()

#: Placeholder returned in place of a stored secret.  Submitting it back means
#: "leave this alone" — otherwise every settings save would need the user to
#: retype credentials they have already entered.
SECRET_PLACEHOLDER = "__set__"

#: Generous cap for a plugin package fetched from a URL (e.g. GitHub Pages) —
#: plugins are Python + a manifest, not media, so anything near this is
#: already suspicious rather than a legitimate package.
_MAX_REMOTE_PLUGIN_BYTES = 200 * 1024 * 1024


def _download_plugin_source(url: str) -> Path:
    """Fetch a remote plugin package to a temp file for ``PluginManager.install``.

    Runs on a worker thread (see the ``asyncio.to_thread`` call site) since
    ``requests`` is blocking. Streams with a hard size cap rather than trusting
    Content-Length, which a server can simply lie about or omit.
    """

    fd, tmp_name = tempfile.mkstemp(prefix="plugin-download-", suffix=".zip")
    tmp_path = Path(tmp_name)
    try:
        with open(fd, "wb") as f:
            with requests.get(url, stream=True, timeout=30, allow_redirects=True) as resp:
                if resp.status_code >= 400:
                    raise PluginError(f"Download failed: HTTP {resp.status_code}")
                written = 0
                for chunk in resp.iter_content(chunk_size=1024 * 64):
                    written += len(chunk)
                    if written > _MAX_REMOTE_PLUGIN_BYTES:
                        raise PluginError("Plugin package exceeds the 200MB download limit")
                    f.write(chunk)
        return tmp_path
    except Exception:
        tmp_path.unlink(missing_ok=True)
        raise


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _manager() -> PluginManager:
    manager = getattr(get_container(), "plugin_manager", None)
    if manager is None:
        raise HTTPException(status_code=503, detail="Plugin manager not initialized")
    return manager


def _registry() -> PluginRegistry:
    registry = getattr(get_container(), "plugin_registry", None)
    if registry is None:
        raise HTTPException(status_code=503, detail="Plugin registry not initialized")
    return registry


def _tracker():
    return getattr(get_container(), "tracker_service", None)


def _catalog():
    return getattr(get_container(), "catalog_service", None)


def _notify_catalog_changed(plugin_id: Optional[str] = None) -> None:
    """Tell the catalog facade the plugin set moved.

    Called on every mutation, not only for catalog-category plugins: the facade
    caches its list definitions against the registry version, and shadowing means
    one plugin changing state can hide or reveal a *different* source.  Deciding
    here which changes are relevant would put that knowledge in two places.
    """

    catalog = _catalog()
    if catalog is not None:
        catalog.on_enabled_changed(plugin_id)


def _require(plugin_id: str) -> PluginRecord:
    record = _registry().get(plugin_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Plugin '{plugin_id}' is not installed")
    return record


def _raise_for_envelope(result: Dict[str, Any], *, default_status: int = 502) -> None:
    """Turn a plugin error envelope into the matching HTTP error."""

    if is_ok(result):
        return
    code = error_code(result) or ErrorCode.INTERNAL_ERROR
    error = result.get("error") or {}
    raise HTTPException(
        status_code=ERROR_HTTP_STATUS.get(code, default_status),
        detail=error.get("message") or code,
    )


def _auth_state(record: PluginRecord) -> Dict[str, Any]:
    """Auth status for a plugin, whoever owns the flow."""

    manifest = record.manifest
    if not manifest.auth.requires_auth:
        return {"required": False, "connected": True}

    if manifest.auth.is_custom:
        result = _manager().execute(record.plugin_id, "tracker.auth.status")
        if not is_ok(result):
            return {"required": True, "connected": False, "status": error_code(result)}
        return {"required": True, **response_data(result)}

    authenticator = _manager().host.authenticator_for(record)
    if authenticator is None:
        return {"required": True, "connected": False, "status": "unavailable"}
    return {"required": True, **authenticator.status()}


def _summary(record: PluginRecord) -> Dict[str, Any]:
    payload = record.as_dict()
    payload["auth"] = _auth_state(record)
    return payload


# ---------------------------------------------------------------------------
# Categories — registered before /{plugin_id} so the paths do not collide
# ---------------------------------------------------------------------------


@router.get("/categories")
async def list_categories() -> Dict[str, Any]:
    """Every plugin category and what is installed in it.

    One call drives the whole Plugins panel, including empty categories — those
    still render, so the extension points are visible before anything exists.
    """

    registry = _registry()
    categories: List[Dict[str, Any]] = []
    for category in PLUGIN_CATEGORIES:
        records = registry.by_category(category.id)
        active = next((r for r in records if r.enabled), None)
        categories.append(
            {
                **category.as_dict(),
                "installed": [_summary(r) for r in records],
                "active_plugin_id": active.plugin_id if active else None,
            }
        )
    return {"categories": categories}


@router.get("/categories/{category}/active")
async def get_active_plugin(category: str) -> Dict[str, Any]:
    if get_category(category) is None:
        raise HTTPException(status_code=404, detail=f"Unknown category '{category}'")
    active = _registry().active_for_category(category)
    return {"category": category, "plugin_id": active.plugin_id if active else None}


@router.put("/categories/{category}/active")
async def set_active_plugin(
    category: str, payload: Dict[str, Any] = Body(default_factory=dict)
) -> Dict[str, Any]:
    """Select the active plugin for a category, or ``null`` for none.

    "None" is a first-class choice: a user turning tracking off entirely should
    not have to uninstall anything.
    """

    if get_category(category) is None:
        raise HTTPException(status_code=404, detail=f"Unknown category '{category}'")

    plugin_id = payload.get("plugin_id")
    plugin_id = str(plugin_id) if plugin_id else None
    if plugin_id is not None:
        record = _require(plugin_id)
        if record.category != category:
            raise HTTPException(
                status_code=400,
                detail=f"Plugin '{plugin_id}' is not a {category} plugin",
            )

    tracker = _tracker()
    previous = _registry().active_for_category(category)

    try:
        if plugin_id is None:
            _registry().set_active_for_category(category, None)
            if previous is not None:
                _manager().host.release(previous.plugin_id)
        else:
            _manager().set_enabled(plugin_id, True)
    except PluginError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    if tracker is not None:
        tracker.on_active_changed(previous.plugin_id if previous else None)
    _notify_catalog_changed(plugin_id)

    active = _registry().active_for_category(category)
    return {
        "category": category,
        "plugin_id": active.plugin_id if active else None,
        "installed": [_summary(r) for r in _registry().by_category(category)],
    }


# ---------------------------------------------------------------------------
# Install / list / remove
# ---------------------------------------------------------------------------


@router.get("")
@router.get("/")
async def list_plugins(category: Optional[str] = Query(default=None)) -> Dict[str, Any]:
    records = _registry().all()
    if category:
        records = [r for r in records if r.category == category]
    return {"plugins": [_summary(r) for r in records], "count": len(records)}


@router.post("/install")
async def install_plugin(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    """Install from a path on the server's filesystem, or an http(s) URL.

    The source comes from the file-browser modal, which is why this takes a
    path/URL rather than an upload — the picker already browses the backend
    filesystem (``GET /api/v1/files/browse``) or resolves a remote URL
    (``GET /api/v1/files/browse-remote``), and either way the backend is
    where the plugin has to land. A URL source (e.g. a package published on
    GitHub Pages) is downloaded to a temp file first, then installed exactly
    like a local pick; the temp file is removed either way.
    """

    source = str(payload.get("source") or "").strip()
    if not source:
        raise HTTPException(status_code=400, detail="source path is required")

    scheme = urlsplit(source).scheme
    if scheme in ("http", "https"):
        try:
            path = await asyncio.to_thread(_download_plugin_source, source)
        except PluginError as exc:
            raise HTTPException(status_code=400, detail=str(exc))
        except requests.RequestException as exc:
            raise HTTPException(status_code=502, detail=f"Could not download plugin: {exc}")
        try:
            try:
                record = _manager().install(path)
            except PluginError as exc:
                raise HTTPException(status_code=400, detail=str(exc))
        finally:
            path.unlink(missing_ok=True)
        log.info("plugin_installed_via_api", plugin_id=record.plugin_id, source="url")
        return {"plugin": _summary(record)}

    path = Path(source).expanduser()
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Source '{source}' not found")

    try:
        record = _manager().install(path)
    except PluginError as exc:
        # A rejected package is the user picking the wrong file, not a server
        # fault — 400 so the UI can show the reason inline.
        raise HTTPException(status_code=400, detail=str(exc))

    log.info("plugin_installed_via_api", plugin_id=record.plugin_id, source="local")
    return {"plugin": _summary(record)}


@router.get("/{plugin_id}")
async def get_plugin(plugin_id: str) -> Dict[str, Any]:
    record = _require(plugin_id)
    payload = record.as_dict(include_manifest=True)
    payload["auth"] = _auth_state(record)
    return {"plugin": payload}


@router.delete("/{plugin_id}")
async def uninstall_plugin(
    plugin_id: str, force: bool = Query(default=False)
) -> Dict[str, Any]:
    record = _require(plugin_id)
    if record.enabled and not force:
        raise HTTPException(
            status_code=409,
            detail="Plugin is enabled; disable it first or pass force=true",
        )

    tracker = _tracker()
    try:
        _manager().uninstall(plugin_id)
    except PluginError as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    if tracker is not None:
        tracker.on_active_changed(plugin_id)
    _notify_catalog_changed(plugin_id)
    return {"uninstalled": plugin_id}


@router.post("/{plugin_id}/enable")
async def enable_plugin(plugin_id: str) -> Dict[str, Any]:
    record = _require(plugin_id)
    previous = _registry().active_for_category(record.category)
    try:
        updated = _manager().set_enabled(plugin_id, True)
    except PluginError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    tracker = _tracker()
    if tracker is not None:
        tracker.on_active_changed(previous.plugin_id if previous else None)
    _notify_catalog_changed(plugin_id)
    return {
        "plugin": _summary(updated),
        "installed": [_summary(r) for r in _registry().by_category(updated.category)],
    }


@router.post("/{plugin_id}/disable")
async def disable_plugin(plugin_id: str) -> Dict[str, Any]:
    record = _require(plugin_id)
    try:
        updated = _manager().set_enabled(plugin_id, False)
    except PluginError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    tracker = _tracker()
    if tracker is not None:
        tracker.on_active_changed(plugin_id)
    _notify_catalog_changed(plugin_id)
    return {
        "plugin": _summary(updated),
        "installed": [_summary(r) for r in _registry().by_category(record.category)],
    }


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------


@router.get("/{plugin_id}/settings-schema")
async def get_settings_schema(plugin_id: str) -> Dict[str, Any]:
    """The plugin's settings page, ready to render.

    The plugin supplies sections and current values from its own tables; the host
    layers on the things it owns — whether this plugin is active, and the OAuth
    session state — and fills in any ``auth_panel`` field with live status.
    """

    record = _require(plugin_id)
    manifest = record.manifest
    ui = manifest.settings_ui or {}

    sections: List[Dict[str, Any]] = []
    if manifest.has_settings_ui or manifest.supports(LifecycleAction.SETTINGS_SCHEMA):
        result = _manager().execute(plugin_id, LifecycleAction.SETTINGS_SCHEMA)
        if is_ok(result):
            raw = response_data(result).get("sections")
            if isinstance(raw, list):
                sections = [s for s in raw if isinstance(s, dict)]
        elif error_code(result) != ErrorCode.UNSUPPORTED_ACTION:
            log.warning(
                "plugin_settings_schema_failed",
                plugin_id=plugin_id,
                error=error_code(result),
            )

    auth = _auth_state(record)
    for section in sections:
        for field in section.get("fields") or []:
            if isinstance(field, dict) and field.get("type") == "auth_panel":
                field["auth_kind"] = manifest.auth.kind
                field["state"] = auth

    return {
        "plugin_id": plugin_id,
        "title": ui.get("title") or record.name,
        "icon": ui.get("icon") or manifest.icon,
        "description": ui.get("description") or manifest.description,
        "category": record.category,
        "version": record.version,
        "active": record.enabled,
        "auth": auth,
        "sections": sections,
    }


@router.put("/{plugin_id}/settings")
async def save_settings(
    plugin_id: str, payload: Dict[str, Any] = Body(default_factory=dict)
) -> Dict[str, Any]:
    """Hand submitted values to the plugin to persist.

    Fields left at the secret placeholder are stripped before dispatch, so a
    plugin never receives ``"__set__"`` as if it were a real value.
    """

    _require(plugin_id)
    values = payload.get("values")
    if not isinstance(values, dict):
        raise HTTPException(status_code=400, detail="values object is required")

    cleaned = {k: v for k, v in values.items() if v != SECRET_PLACEHOLDER}

    result = _manager().execute(
        plugin_id, LifecycleAction.SETTINGS_SAVE, {"values": cleaned}
    )
    _raise_for_envelope(result, default_status=400)
    return {"saved": response_data(result).get("saved", list(cleaned)), "ok": True}


@router.post("/{plugin_id}/actions/{action_id}")
async def run_plugin_action(
    plugin_id: str, action_id: str, payload: Dict[str, Any] = Body(default_factory=dict)
) -> Dict[str, Any]:
    """Run an ``action_button`` declared on the plugin's settings page.

    The action must appear in the plugin's current schema — this endpoint is not
    a general remote-invoke for arbitrary action names.
    """

    _require(plugin_id)

    schema = await get_settings_schema(plugin_id)
    declared = {
        field.get("id")
        for section in schema["sections"]
        for field in (section.get("fields") or [])
        if isinstance(field, dict) and field.get("type") == "action_button"
    }
    if action_id not in declared:
        raise HTTPException(
            status_code=404,
            detail=f"Plugin '{plugin_id}' declares no action '{action_id}'",
        )

    result = _manager().execute(plugin_id, LifecycleAction.action(action_id), payload)
    _raise_for_envelope(result)
    return {"ok": True, "result": response_data(result)}


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------


def _authenticator(record: PluginRecord):
    manifest = record.manifest
    if not manifest.auth.requires_auth:
        raise HTTPException(status_code=400, detail="Plugin does not require authentication")
    if manifest.auth.is_custom:
        return None
    authenticator = _manager().host.authenticator_for(record)
    if authenticator is None:
        raise HTTPException(status_code=503, detail="Authenticator unavailable")
    return authenticator


@router.post("/{plugin_id}/auth/start")
async def auth_start(plugin_id: str) -> Dict[str, Any]:
    record = _require(plugin_id)
    authenticator = _authenticator(record)
    if authenticator is None:
        result = _manager().execute(plugin_id, "tracker.auth.start")
        _raise_for_envelope(result)
        return response_data(result)

    try:
        return authenticator.start()
    except ValueError as exc:
        # Missing credentials — the user has not filled in the settings page yet.
        raise HTTPException(status_code=409, detail=str(exc))
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"Device code request failed: {exc}")


@router.get("/{plugin_id}/auth/status")
async def auth_status(plugin_id: str) -> Dict[str, Any]:
    return _auth_state(_require(plugin_id))


@router.post("/{plugin_id}/auth/poll")
async def auth_poll(plugin_id: str) -> Dict[str, Any]:
    """Current state of an in-flight device authorisation.

    The host polls the provider on a background thread, so this is a cheap local
    read — the client can poll it as often as it likes without adding upstream
    traffic or risking a rate limit.
    """

    record = _require(plugin_id)
    authenticator = _authenticator(record)
    if authenticator is None:
        result = _manager().execute(plugin_id, "tracker.auth.poll")
        _raise_for_envelope(result)
        return response_data(result)
    return authenticator.status()


@router.post("/{plugin_id}/auth/clear")
async def auth_clear(plugin_id: str) -> Dict[str, Any]:
    record = _require(plugin_id)
    authenticator = _authenticator(record)
    if authenticator is None:
        result = _manager().execute(plugin_id, "tracker.auth.clear")
        _raise_for_envelope(result)
        return response_data(result)

    authenticator.clear_token()
    return {"connected": False, "cleared": True}


@router.get("/{plugin_id}/account")
async def plugin_account(plugin_id: str) -> Dict[str, Any]:
    _require(plugin_id)
    result = _manager().execute(plugin_id, "tracker.account")
    _raise_for_envelope(result)
    return response_data(result)


__all__ = ["router"]
