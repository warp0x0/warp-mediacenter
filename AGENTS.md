# AGENTS.md - Warp MediaCenter

## Repo Shape

- `warp_mediacenter/` is the Python backend/runtime package; there is no `pyproject.toml` or `setup.py`, so run module commands from the repo root.
- `flutter_client/` is the active Flutter client. There is currently no tracked `frontend/` directory; `scripts/prepare_tauri_mpv_sidecar.py` still targets that absent tree.
- `Torrent-Api-py/` is a nested git repo with its own `AGENTS.md`; read that file before editing inside it. Root startup can launch its `main.py`.
- `warp-mediacenter-client/` and `Resources/` are ignored by root `.gitignore`; do not treat them as tracked app code unless explicitly asked.

## Commands

- Python deps: `pip install -r requirements.txt`
- Backend startup smoke: `python -m warp_mediacenter.warpmc_startup`
- CLI discovery: `python -m warp_mediacenter.cli.media --help` and `python -m warp_mediacenter.cli.admin --help`
- Full API server with services wired: `python -m warp_mediacenter.cli.media serve --host 0.0.0.0 --port 8000`
- API + Torrent-API-Py: `python -m warp_mediacenter.cli.media warp-startup --port 8000 --torrent-port 8009`
- API contract smoke: `python scripts/phase6_contract_smoke.py` requires `httpx`, which is not in root `requirements.txt`.
- Python focused verification: `python -m py_compile <changed .py files>` plus the relevant CLI/API smoke above; no pytest config or Python linter/type checker is present.
- Flutter setup/checks from `flutter_client/`: `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`
- Single Flutter test from `flutter_client/`: `flutter test test/widget_test.dart`

## Backend Notes

- Prefer `python -m warp_mediacenter.cli.media serve` over direct `uvicorn warp_mediacenter.backend.api.app:create_app --factory`; the CLI initializes `ServiceContainer` and legacy route globals before creating the app.
- `warp-media ui` imports missing `warp_mediacenter.ui.app`; do not use it as a working desktop entrypoint unless adding that package.
- FastAPI routes are registered in `warp_mediacenter/backend/api/app.py` under `/api/v1/*`; service wiring lives in `warp_mediacenter/cli/api_server.py` and `warp_mediacenter/backend/api/middleware/container.py`.
- Settings load `warp_mediacenter/.env` (not repo-root `.env`). JSON config placeholders like `${TMDB_API_KEY}` expand from `os.environ` and become empty strings if unset.
- Runtime DB/cache/tokens/plugins resolve under `warp_mediacenter/var/`; config paths are in `warp_mediacenter/config/config_paths.json`.
- SQLite schema auto-migrates on `warp_mediacenter/backend/persistence/sqlite.py:connect()`. Add a new incremental migration and bump `_SCHEMA_VERSION`; do not rewrite already-applied migration steps.
- Use `InformationProviders` (`warp_mediacenter/backend/information_handlers/providers.py`) as the TMDb/Trakt/public-archives facade; Trakt can be unavailable while other providers still work.
- Normalized media types/models live in `warp_mediacenter/backend/information_handlers/models.py`; avoid returning raw provider payloads from new API surfaces unless an existing route already does.
- Playback is client-owned. Backend player routes should stay limited to preload sessions, loopback stream proxying, subtitle search/download/file serving, and scrobble endpoints.
- Torrent search depends on RealDebrid and/or Torrent-API-Py. Use `--torrent-executable` or `TORRENT_API_MAIN_PATH` to locate Torrent-API-Py; the `warp-startup` warning mentions `TORRENT_API_EXECUTABLE`, but code does not read it.
- Plugins require a `plugin.json`; entrypoints must be `module:function` (`warp_mediacenter/backend/plugins/manifest.py`).

## Flutter Notes

- `flutter_client/lib/main.dart` initializes `media_kit`, locks landscape, applies immersive Android mode, detects Android TV density, and persists API base URL via Riverpod/shared_preferences.
- API base URL defaults to `http://localhost:8000` in `flutter_client/lib/api/api_client.dart`; Settings can persist a different URL.
- Routing is generated from `flutter_client/lib/navigation/router.dart` with GoRouter/Riverpod; generated `*.g.dart` and `*.freezed.dart` files are tracked.
- Rerun `dart run build_runner build --delete-conflicting-outputs` after changing Riverpod providers, GoRouter routes, or json/freezed models.
- `flutter_client/build.yaml` sets `json_serializable` `field_rename: snake`; keep backend JSON field names aligned with that.
- `flutter_client/analysis_options.yaml` excludes `third_party/**`; do not assume analyzer covers the vendored `better_player_enhanced` plugin.

## Verification Gaps

- No root CI, pre-commit, Makefile/task runner, Python formatter, Python linter, mypy, or pytest config is present.
- Root `README.md` and `warp_mediacenter/backend/information_handlers/README.md` are empty; trust executable config and source over those docs.
