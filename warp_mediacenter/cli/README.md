# Warp MediaCenter CLI Guide

Warp MediaCenter now exposes two dedicated command line interfaces to inspect and
operate the application without starting the graphical shell. Each CLI is
implemented as a Python module and can be invoked with ``python -m`` or wired
into an executable entry point when packaging the project.

- **`warp-admin`** – manages configuration files, library paths, and plugin
  metadata.
- **`warp-media`** – provides media-centric operations such as TMDb searches,
  Trakt authentication, and public-domain catalog exploration.

Both CLIs ship comprehensive ``--help`` output at every level. Use
``python -m warp_mediacenter.cli.admin --help`` or
``python -m warp_mediacenter.cli.media --help`` to browse the available
subcommands.

## Admin CLI (`warp-admin`)

Launch the administrative CLI with:

```bash
python -m warp_mediacenter.cli.admin <command> [options]
```

### Core commands

| Command | Description |
| --- | --- |
| `settings show` | Display the effective runtime settings (add `--reload` to refresh from disk first). |
| `settings update [--app-name NAME] [--env ENV] [--log-level LEVEL] [--task-workers N]` | Persist updates to user settings. |
| `settings paths show` | Print the configured movie and show library locations. |
| `settings paths set <movie|show> <PATH>` | Update a library root and persist it to the user settings file. |
| `settings plugins` | List installed plugins recorded in the settings payload. |
| `paths show [--raw]` | Display resolved configuration file locations (`--raw` shows the underlying JSON). |
| `paths set <KEY> <PATH>` | Override entries in `config_paths.json` and reload the mapping. |
| `paths reload` | Recompute and display the effective path mapping. |
| `providers list` | Show all configured provider sections loaded from `informationproviderservicesettings.json`. |
| `providers show <SERVICE>` | Inspect a single provider configuration block. |
| `providers endpoints <SERVICE>` | Display the configured REST endpoints for a provider. |
| `providers pipelines [PIPELINE]` | List pipelines or inspect a specific pipeline definition. |
| `providers content-lists [KEY]` | Show the curated content list catalog or a single entry. |
| `providers public-domain [SOURCE]` | Inspect configuration for public-domain sources. |
| `providers proxy` / `providers reload-proxy` | Inspect or reload the proxy configuration. |
| `providers reload` | Reload information provider settings from disk. |
| `plugins list` | List plugin registry entries. |
| `plugins register` | Register a plugin (accepts arguments such as `--plugin-id`, `--entrypoint`, `--path`, and optional metadata flags). |
| `plugins remove <ID>` | Remove a plugin entry from the registry. |
| `db info` | Display the SQLite database path along with file size and timestamps. |
| `db migrate` | Run database migrations to create or update the schema. |
| `db stats` | Show row counts for core tables plus page-level storage metrics. |
| `db vacuum` | Execute `VACUUM` to reclaim free space in the SQLite file. |
| `db widgets list` | List cached catalog widget keys stored in SQLite. |
| `db widgets show <KEY> [--raw]` | Inspect the payload for a cached widget (use `--raw` to print the stored JSON string). |
| `db widgets clear <KEY>` | Remove a cached widget payload from the database. |

All commands print JSON to stdout to simplify scripting and integration.

## Media CLI (`warp-media`)

Launch the media CLI with:

```bash
python -m warp_mediacenter.cli.media <command> [options]
```

### Search helpers

| Command | Description |
| --- | --- |
| `search tmdb <QUERY> [--media-type movie|show] [--language LANG] [--page N] [--include-adult]` | Perform TMDb catalog searches. |
| `search trakt <QUERY> [--media-type TYPE] [--limit N] [--year YYYY]` | Query Trakt (requires configured OAuth credentials). |
| `search public-domain <SOURCE> [--param KEY=VALUE ...]` | Fetch catalog entries from configured public-domain sources. |

### TMDb utilities

| Command | Description |
| --- | --- |
| `tmdb movie <MOVIE_ID> [--language LANG] [--skip-credits]` | Fetch full TMDb movie metadata. |
| `tmdb show <SHOW_ID> [--language LANG] [--skip-credits]` | Fetch detailed TMDb show metadata. |
| `tmdb catalog <CATEGORY> [--media-type movie|show] [--language LANG] [--page N]` | Retrieve TMDb catalog listings such as popular, now_playing, or top_rated. |

### Public-domain catalogs

| Command | Description |
| --- | --- |
| `public-domain list-sources` | List configured remote public-domain providers. |
| `public-domain curated [CATALOG]` | List available curated catalogs or render a selected catalog. |
| `public-domain fetch <SOURCE> [--param KEY=VALUE ...]` | Fetch entries from a remote public-domain source. |

### Trakt tooling

The following commands require valid Trakt API credentials in the settings
(`TRAKT_CLIENT_ID` and `TRAKT_CLIENT_SECRET`) and, for user data, a completed
OAuth device flow.

| Command | Description |
| --- | --- |
| `trakt auth start` | Begin the OAuth device authorization flow. |
| `trakt auth poll <DEVICE_CODE>` | Poll the device endpoint to obtain tokens (exit code 2 indicates `authorization_pending`). |
| `trakt auth status` | Display current token status and expiry information. |
| `trakt auth clear` | Remove cached OAuth tokens. |
| `trakt profile [--username USER]` | Fetch profile data for the authenticated user or a specified username. |
| `trakt lists [--username USER]` | List custom Trakt lists for a user. |
| `trakt list-items <LIST_ID> [--username USER] [--media-type TYPE]` | Render the entries from a specific Trakt list. |
| `trakt history [--media-type TYPE] [--limit N]` | Display watched history for the authenticated user. |
| `trakt catalog <CATEGORY> [--media-type movie|show] [--period WINDOW] [--limit N] [--username USER]` | Fetch Trakt catalog categories including trending, popular, watched, or user list collections. |
| `trakt in-progress [--media-type movie|show]` | Show in-progress playback items filtered by media type. |
| `trakt search <QUERY> [...]` | Trakt search shortcut that requires authentication. |

### Endpoint inspection

| Command | Description |
| --- | --- |
| `endpoints <SERVICE>` | Print the REST endpoint configuration for TMDb, Trakt, public-domain providers, or other services defined in the settings file. |

All media commands emit JSON output that mirrors the underlying models, making
it easy to pipe results into `jq` or other tooling.

## Development notes

- Both CLIs live under `warp_mediacenter/cli/` and can be extended with new
  commands by following the existing argparse structure.
- Errors are reported on stderr and return a non-zero exit status to facilitate
  automation.
- The CLIs reuse the existing settings package, so configuration changes made
  through `warp-admin` immediately affect subsequent `warp-media` commands.

For additional details about provider configuration, inspect the files in
`warp_mediacenter/config/` and the modules inside `warp_mediacenter/backend/`.
