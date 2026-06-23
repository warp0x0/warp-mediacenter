# AGENTS.md — Warp MediaCenter

## Project Overview

Python media center app with a Tauri desktop shell. Manages, catalogs, and plays local media files with TMDb/Trakt integration. Two-tier architecture: Python backend (FastAPI + SQLite) and React/TypeScript frontend wrapped by Tauri (mpv for native playback).

## Key Commands

```bash
# Install Python deps
pip install -r requirements.txt

# Install frontend deps
cd frontend && npm install

# Startup smoke test
python -m warp_mediacenter.warpmc_startup

# FastAPI dev server
uvicorn warp_mediacenter.backend.api.app:create_app --factory --reload

# Media CLI (search, catalogs, Trakt auth, public domain)
python -m warp_mediacenter.cli.media --help
python -m warp_mediacenter.cli.media search tmdb "Inception" --media-type movie
python -m warp_mediacenter.cli.media trakt auth start
python -m warp_mediacenter.cli.media public-domain list-sources

# Admin CLI (settings, plugins, database, provider config)
python -m warp_mediacenter.cli.admin --help
python -m warp_mediacenter.cli.admin settings show
python -m warp_mediacenter.cli.admin db stats
python -m warp_mediacenter.cli.admin providers list

# Tauri desktop dev (builds mpv sidecar first)
cd frontend && npm run tauri:dev

# mpv sidecar preparation (run before Tauri dev/build)
python scripts/prepare_tauri_mpv_sidecar.py
```

## Architecture

```
warp_mediacenter/                  # Python package root
  cli/                             # CLI entry points (media.py, admin.py)
  backend/
    api/                           # FastAPI app, routes, middleware
      app.py                       # FastAPI factory (create_app)
      routes/                      # torrent, stream, images, scrobble, library,
                                   #   player, subtitles, trakt, debrid, settings,
                                   #   discovery (search + catalog)
      middleware/                   # CORS, error handler, request logging, ServiceContainer
    library/                       # File scanning, filename parsing (guessit), artwork download
    player/                        # Playback engine (adapter pattern)
      service.py                   # Player-agnostic playback logic
      adapter.py                   # PlayerAdapter interface
      vlc_adapter.py               # VLC desktop adapter
      http_adapter.py              # HTTP thin-client adapter
      debrid/                      # RealDebrid torrent streaming
      subtitles/                   # Subtitle discovery + download
    information_handlers/          # TMDb, Trakt, public archives, trailers managers
      providers.py                 # InformationProviders unified facade
      models.py                    # Normalized Pydantic models (Movie, Show, CatalogItem...)
    persistence/                   # SQLite (titles, episodes, sources, play_history, settings, widgets)
    plugins/                       # Plugin system (manifest-based, zip/dir install)
    resource_management/           # Adaptive tuning via psutil (RAM/CPU-aware worker counts)
    network_handlers/              # HTTP sessions, proxy management, rate limiting
    common/                        # Logging, tasks, types, errors
  config/
    config_paths.json              # Relative path definitions (resolved from project root)
    informationproviderservicesettings.json  # Provider endpoints, rate limits, API key placeholders
    proxysettings.json             # Proxy configuration
    settings/                      # Pydantic-backed settings modules
  resources/                       # App resources

frontend/                          # React + TypeScript + Vite
  src/                             # React app (components, hooks, contexts, pages)
    hooks/
      useRemoteNav.ts              # Android TV D-pad remote navigation (explicit zone transitions)
      useFocusTrap.ts              # Modal focus trapping (Tab cycling, Escape to close)
    components/shared/
      ContextMenu.tsx              # Long-press context menu overlay (AnimatePresence + focus trap)
      HelpDialog.tsx               # Keyboard shortcuts overlay
    components/media/
      WidgetSection.tsx            # Ribbon + hero backdrop rows (remote nav + long-press wired)
    components/cards/
      CatalogRow.tsx               # Horizontal poster grid (remote nav + long-press wired)
  src-tauri/                       # Tauri Rust shell
    src/main.rs                    # mpv IPC bridge, native player commands
    tauri.conf.json                # Tauri config (sidecar, bundled resources)
    Cargo.toml                     # Rust deps (tauri 2, serde)

scripts/
  prepare_tauri_mpv_sidecar.py     # Downloads mpv binary for Tauri sidecar
  phase6_contract_smoke.py         # API contract smoke test
```

## Configuration Quirks

- **Path resolution**: `config_paths.json` uses paths relative to project root. Always run from project root.
- **API key placeholders**: JSON configs use `${ENV_VAR}` syntax (e.g., `${TMDB_API_KEY}`, `${TRAKT_CLIENT_ID}`). Resolved at runtime via `os.environ`.
- **Runtime data**: `var/` is gitignored — holds cache, tokens, logs. Do not commit anything under `var/`.
- **Trakt auth**: Requires `TRAKT_CLIENT_ID` and `TRAKT_CLIENT_SECRET`. Uses OAuth device flow — start with `trakt auth start`, then poll with the returned device code.
- **mpv sidecar**: Tauri bundles mpv as a sidecar binary. Run `python scripts/prepare_tauri_mpv_sidecar.py` before `tauri dev` or `tauri build`. Binary lives in `frontend/src-tauri/bin/`.
- **mpv config**: uosc OSC scripts bundled in `frontend/src-tauri/resources/mpv-config/`. Tauri bundles these as resources.
- **Env files**: `.env` is gitignored. `.env.example` exists at package root for reference.

## Important Patterns

- **`InformationProviders`** (`backend/information_handlers/providers.py`) is the unified facade for all provider calls. Use it instead of calling individual managers directly.
- **Normalized models** (`backend/information_handlers/models.py`) — all provider responses converted to Pydantic models via `MediaModelFacade`.
- **PlayerAdapter pattern** (`backend/player/adapter.py`) — player-agnostic interface. `vlc_adapter.py` for desktop, `http_adapter.py` for thin clients. `service.py` contains all shared playback logic.
- **SQLite persistence** (`backend/persistence/sqlite.py`) — auto-migrates on connect. Tables: `titles`, `episodes`, `sources`, `play_history`, `settings`, `catalog_widgets`.
- **Resource-aware tasks** — `TaskRunner` + `ResourceManager` adapt concurrency based on system RAM/CPU. Always pass `resource_manager` when creating runners.
- **Plugin entrypoints** must be `module:function` format. Plugins require a `plugin.json` manifest at their root.
- **FastAPI routes** are registered in `backend/api/app.py` under `/api/v1/` prefix. Service dependencies injected via `ServiceContainer` middleware.
- **Tauri IPC** — Rust side (`main.rs`) manages mpv via Unix socket IPC. React communicates with mpv through Tauri commands (`player_open_window`, `player_pause`, etc.). Events emitted as `native-player-status`.
- **Remote D-pad navigation** — `useRemoteNav` (mounted at App root) intercepts Arrow/Enter/Backspace keys for Android TV remote control. Uses explicit zone transitions: Up from content → TabBar, Down from TabBar → first content element, Left/Right sequential in ribbons and tabbars. Components declare zones via `data-nav-ribbon`, `data-nav-tabbar`, `data-nav-initial-focus` attributes.
- **Modal focus trapping** — `useFocusTrap` saves/restores focus, traps Tab cycling within the dialog container, Escape to close. Applied to all modal/dialog components (TorrentDialog, SubtitleDialog, HelpDialog, AuthDialog, FileBrowserModal, ScanDialog, TrailerDialog, ResumeModal).
- **Long-press context menus** — `useRemoteNav` fires `remotelongpress` CustomEvent on `document.activeElement` after 600ms hold. Components listen via event delegation on containers. `ContextMenu` component provides positioned overlay with focus trap. Context menu items: "Mark as Watched" (updates local play_history + Trakt `/sync/history`).
- **Mark as Watched API** — `POST /api/v1/library/mark-watched` records a full-progress play_history entry in SQLite and syncs to Trakt via `POST /sync/history/{movies|episodes}`. Resolves title_id from tmdb_id, looks up Trakt IDs via TMDb→Trakt mapping.

## Current State

- **No tests** — test suite not yet created.
- **No lint/typecheck/formatter** — no ruff, mypy, black, or similar configured for Python. Frontend has ESLint via Vite template.
- **No CI/CD** — no GitHub Actions or pre-commit hooks.
- **No pyproject.toml/setup.py** — Python dependencies managed via `requirements.txt` only.
- Version: `0.0.1`

## Notebooks

- `notebooks/trakt_integration_demo.ipynb` — Trakt OAuth and API smoke tests
- `notebooks/cli_functionality_test.ipynb` — CLI layer functionality tests
