# AGENTS.md — Warp MediaCenter

## Project Overview

Python media center application (Plex/Jellyfin-like, early stage). Manages, catalogs, and plays local media files with TMDb/Trakt integration.

## Key Commands

```bash
# Install dependencies
pip install -r requirements.txt

# Run startup smoke test
python -m warp_mediacenter.warpmc_startup

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
```

## Architecture

```
warp_mediacenter/
  cli/                  # CLI entry points (media.py, admin.py)
  backend/
    library/            # File scanning, filename parsing (guessit), artwork download
    player/             # VLC playback controller, subtitle orchestration
    information_handlers/  # TMDb, Trakt, public archives, trailers managers
    persistence/        # SQLite database (titles, episodes, sources, play_history, widgets)
    plugins/            # Plugin system (manifest-based, zip/dir install)
    resource_management/ # Adaptive tuning via psutil (RAM/CPU-aware worker counts)
    network_handlers/   # HTTP sessions, proxy management, rate limiting
    common/             # Logging, tasks, types, errors
  config/
    config_paths.json   # Relative path definitions (resolved from project root)
    informationproviderservicesettings.json  # Provider endpoints, rate limits, API key placeholders
    proxysettings.json  # Proxy configuration
    settings/           # Pydantic-backed settings modules
```

## Configuration Quirks

- **Path resolution**: `config_paths.json` uses paths relative to project root. Always run from `/Users/k2_mac/Documents/Workspace/Experiments/warp-mediacenter`.
- **API key placeholders**: JSON configs use `${ENV_VAR}` syntax (e.g., `${TMDB_API_KEY}`, `${TRAKT_CLIENT_ID}`). Resolved at runtime via `os.environ`.
- **Runtime data**: `var/` is gitignored — holds cache, tokens, logs. Do not commit anything under `var/`.
- **Trakt auth**: Requires `TRAKT_CLIENT_ID` and `TRAKT_CLIENT_SECRET`. Uses OAuth device flow — start with `trakt auth start`, then poll with the returned device code.

## Important Patterns

- **`InformationProviders`** (`backend/information_handlers/providers.py`) is the unified façade for all provider calls. Use it instead of calling individual managers directly.
- **Normalized models** (`backend/information_handlers/models.py`) — all provider responses are converted to Pydantic models (`Movie`, `Show`, `CatalogItem`, etc.) via `MediaModelFacade`.
- **SQLite persistence** (`backend/persistence/sqlite.py`) — auto-migrates on connect. Tables: `titles`, `episodes`, `sources`, `play_history`, `settings`, `catalog_widgets`.
- **Resource-aware tasks** — `TaskRunner` + `ResourceManager` adapt concurrency based on system RAM/CPU. Always pass `resource_manager` when creating runners.
- **Plugin entrypoints** must be `module:function` format. Plugins require a `plugin.json` manifest at their root.

## Current State

- **No tests** — test suite not yet created.
- **No lint/typecheck/formatter** — no ruff, mypy, black, or similar configured.
- **No CI/CD** — no GitHub Actions or pre-commit hooks.
- **No pyproject.toml/setup.py** — dependencies managed via `requirements.txt` only.
- **No UI/frontend** — CLI-only at this stage.
- Version: `0.0.1`

## Notebooks

- `notebooks/trakt_integration_demo.ipynb` — Trakt OAuth and API smoke tests
- `notebooks/cli_functionality_test.ipynb` — CLI layer functionality tests
