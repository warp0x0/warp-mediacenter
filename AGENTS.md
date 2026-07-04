# AGENTS.md - Warp MediaCenter

## Repo Shape

- `warp_mediacenter/` is the Python backend/runtime package. There is no `pyproject.toml` or `setup.py`; run Python module commands from the repo root so imports resolve.
- `frontend/` is the React 19 + Vite 8 + Tauri 2 desktop shell. `flutter_client/` is a separate Flutter client. `Torrent-Api-py/` is a nested torrent-service repo with its own `AGENTS.md`; root startup can launch it.
- `warp-mediacenter-client/` is ignored by root `.gitignore`; do not treat it as tracked app code unless the user explicitly asks.

## Commands

- Python deps: `pip install -r requirements.txt`
- Backend startup smoke: `python -m warp_mediacenter.warpmc_startup`
- Full API server with services wired: `python -m warp_mediacenter.cli.media serve --host 0.0.0.0 --port 8000`
- Full stack API + Torrent-API-Py: `python -m warp_mediacenter.cli.media warp-startup --port 8000 --torrent-port 8009`
- CLI discovery: `python -m warp_mediacenter.cli.media --help` and `python -m warp_mediacenter.cli.admin --help`
- API contract smoke: `python scripts/phase6_contract_smoke.py` (requires `httpx`, which is not listed in root `requirements.txt`).
- Frontend setup: `cd frontend && npm install`
- Frontend dev/build/lint: `cd frontend && npm run dev`, `cd frontend && npm run build`, `cd frontend && npm run lint`
- Tauri dev/build: `cd frontend && npm run tauri:dev` or `cd frontend && npm run tauri:build`; `tauri.conf.json` already runs `npm run tauri:prepare-sidecar` before dev/build.
- Focused sidecar prep: `cd frontend && npm run tauri:prepare-sidecar`
- Flutter setup/checks: `cd flutter_client && flutter pub get`, `cd flutter_client && dart run build_runner build --delete-conflicting-outputs`, `cd flutter_client && flutter analyze`, `cd flutter_client && flutter test`

## Backend Notes

- Prefer `python -m warp_mediacenter.cli.media serve` over direct `uvicorn warp_mediacenter.backend.api.app:create_app --factory`; the CLI initializes `ServiceContainer` and legacy route globals before creating the app.
- FastAPI routes are registered in `warp_mediacenter/backend/api/app.py` under `/api/v1/*`; service wiring lives in `warp_mediacenter/cli/api_server.py` and `warp_mediacenter/backend/api/middleware/container.py`.
- Settings load `warp_mediacenter/.env` (not repo-root `.env`). JSON config placeholders like `${TMDB_API_KEY}` expand from `os.environ` and become empty strings if unset.
- Runtime DB/cache/tokens/plugins resolve under `warp_mediacenter/var/`; `var/` directories are gitignored.
- SQLite schema auto-migrates on `warp_mediacenter/backend/persistence/sqlite.py:connect()`. Add a new incremental migration and bump `_SCHEMA_VERSION`; do not rewrite already-applied migration steps.
- Use `InformationProviders` (`backend/information_handlers/providers.py`) as the TMDb/Trakt/public-archives facade; Trakt can be unavailable while other providers still work.
- Normalized media types/models live in `backend/information_handlers/models.py`; avoid returning raw provider payloads from new API surfaces unless an existing route already does.
- Player logic is split between `PlayerController`/`PlaybackService`, adapters (`vlc_adapter.py`, `http_adapter.py`), and Tauri's Rust/mpv native player. Keep shared playback behavior out of frontend-only code when it belongs in `PlaybackService`.
- Torrent search depends on RealDebrid and/or Torrent-API-Py. Env overrides include `TORRENT_API_URL`, `TORRENT_API_KEY`, `REALDEBRID_*`, and `TORRENT_API_MAIN_PATH` for locating `Torrent-Api-py/main.py`.
- Plugins require a `plugin.json`; entrypoints must be `module:function` (`backend/plugins/manifest.py`).

## Frontend Notes

- Frontend API base URL is `VITE_API_BASE_URL` with fallback `http://localhost:8000` (`frontend/src/lib/api.ts`). Vite uses strict port `1420`.
- Tauri IPC wrappers live in `frontend/src/lib/tauri.ts`; Rust commands and mpv IPC live in `frontend/src-tauri/src/main.rs`. Native player status is emitted as `native-player-status`.
- The mpv sidecar script creates `frontend/src-tauri/bin/mpv-aarch64-apple-darwin` and `frontend/src-tauri/bin/macos-arm64/lib/*`; check generated sidecar artifacts before committing because only the `macos-arm64/` folder is ignored by `frontend/.gitignore`.
- Remote/keyboard navigation is centralized in `frontend/src/navigation/NavigationProvider.tsx`. Register focus targets with `data-nav-item`, `data-nav-id`, `data-nav-group`, `data-nav-axis`, `data-nav-initial`, and `useNavItem`; do not reintroduce a separate `useRemoteNav` hook.
- Modals participate in navigation with `data-nav-modal`, close via `data-nav-modal-close`, and may delegate arrows with `data-nav-delegate-arrows`/`navmodalarrow`. `useFocusTrap` also looks for `data-nav-initial`.
- Context menus are opened by `NavigationProvider` long-press/right-click via each item’s `getContextMenu`; shared media menu items live in `frontend/src/navigation/useMediaContextMenuItems.tsx`.

## Flutter Notes

- `flutter_client/lib/main.dart` initializes `media_kit`, locks landscape, detects Android TV density, and persists the API base URL via Riverpod/shared_preferences.
- Generated Dart files are part of the current client (`*.g.dart`); rerun `dart run build_runner build --delete-conflicting-outputs` after changing Riverpod providers, GoRouter routes, or json/freezed models.
- `flutter_client/build.yaml` sets `json_serializable` `field_rename: snake`; keep backend JSON field names aligned with that.

## Verification Gaps

- No root CI, pre-commit, Python formatter, Python linter, mypy, or pytest config is present.
- For Python changes, use targeted `python -m py_compile <files>` plus the relevant CLI/API smoke command; for frontend changes use `npm run lint` and `npm run build` from `frontend/`.
