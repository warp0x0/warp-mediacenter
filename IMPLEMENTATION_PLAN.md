# Warp MediaCenter — Complete Implementation Plan

> **Status tracking file** — survives context compaction. Update `[x]` flags as phases complete.
> **Last updated:** 2026-05-23

---

## Architecture Overview

```
Thin Client (Android TV / Browser)
    │
    ▼
FastAPI Backend (warp_mediacenter/backend/api/)
    │
    ├── Library & Catalog API ────► SQLite DB + TMDb/Trakt providers
    ├── Discovery & Search API ───► TMDb + Trakt + Local search
    ├── Player Control API ───────► VLCAdapter + Subtitle orchestration
    ├── Torrent Stream API ───────► TorrentSearch + RealDebrid
    ├── Trakt + RealDebrid API ───► OAuth flows + account management
    ├── Subtitle API ─────────────► OpenSubtitles/Podnapisi search + download
    └── Settings & Management API ─► Config + library scan
    │
    ▼
Backend Services (player/, information_handlers/, library/, persistence/)
```

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| `thefuzz` for fuzzy matching | C deps OK on Pi; more accurate than stdlib `difflib` |
| Custom RD app → full OAuth2 device flow | Secure, reusable, matches Trakt pattern |
| All external traffic via VPN | OS-level routing; LAN discovery via explicit bind |
| Real-time progress via SSE | Simpler than WebSocket, ~40 lines in FastAPI |
| Bundled module (no plugin.json yet) | Personal project; plugin system later for app stores |
| Episode search auto-appends `S{season:02d}E{episode:02d}` | Matches user flow: series poster → episode list → click episode → search |
| Cached vs uncached split in UI | Instant play vs "busify until download complete" |
| API target: both thin client + internal CLI | Single API serves Android TV ExoPlayer and CLI testing |
| No auth middleware | Local network only; auth deferred |
| Server-side subtitle management | Server has VLC for rendering, API keys live on server, auto-cleanup |
| Thin client renders subtitles | Client (ExoPlayer) handles subtitle display; server provides files |

---

## Phase 1: Settings Module for Torrent & RealDebrid `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/config/settings/torrent.py` — `TorrentSettings`, `RealDebridSettings`, `TorrentDebridSettings`
- Updated `warp_mediacenter/config/settings/__init__.py` — added exports

**Files modified:**
- `requirements.txt` — added `thefuzz==0.22.1`, `aiohttp==3.11.12`, `fastapi==0.115.6`, `uvicorn==0.34.0`

**What it does:**
- `TorrentSettings`: `api_base_url`, `api_key`, `min_seeders`, `max_results`, `preferred_qualities`, `fuzzy_match_threshold`
- `RealDebridSettings`: `base_url`, `oauth_client_id`, `oauth_client_secret`, `access_token`, `refresh_token`, `token_expires_at`, `poll_interval`, `download_timeout`, `prefer_instant`
- Env var overrides: `TORRENT_API_URL`, `TORRENT_API_KEY`, `REALDEBRID_ACCESS_TOKEN`, `REALDEBRID_REFRESH_TOKEN`, `REALDEBRID_CLIENT_ID`, `REALDEBRID_CLIENT_SECRET`
- Persistence via `user_settings.json`
- `has_valid_token` property checks expiry

---

## Phase 2: RealDebrid OAuth2 Device Flow Client `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/player/debrid/__init__.py` — module exports
- `warp_mediacenter/backend/player/debrid/models.py` — Pydantic models (`TorrentFile`, `TorrentInfo`, `UnrestrictLink`, `DeviceCodeResponse`, `DeviceCredentialsResponse`, `TokenResponse`, `HostEntry`)
- `warp_mediacenter/backend/player/debrid/oauth.py` — `RealDebridOAuth` class with full device flow
- `warp_mediacenter/backend/player/debrid/client.py` — `RealDebridClient` class with torrent/link operations

**OAuth2 Device Flow (`oauth.py`):**
- `request_device_code()` → `POST /oauth/v2/device/code?client_id=...&new_credentials=yes`
- `poll_credentials(device_code)` → polls `GET /oauth/v2/device/credentials` every 5s until authorized
- `exchange_token(device_code, client_id, client_secret)` → `POST /oauth/v2/token` with device grant type
- `complete_flow(device_code)` → runs poll + exchange, persists tokens via `update_realdebrid_settings()`
- `refresh_token()` → refreshes expired access token using stored refresh_token
- `ensure_valid_token()` → returns valid token, auto-refreshes if needed

**Client methods (`client.py`):**
- `start_device_auth()` → returns display info (user_code, verification_url)
- `complete_device_auth(device_code)` → completes flow, returns token info
- `add_magnet(magnet)` → `POST /torrents/addMagnet`, returns torrent ID
- `select_files(torrent_id, file_ids="all")` → `POST /torrents/selectFiles/{id}`
- `get_torrent_info(torrent_id)` → `GET /torrents/info/{id}`, returns `TorrentInfo`
- `wait_for_download(torrent_id)` → polls until `status=downloaded` or timeout/error
- `delete_torrent(torrent_id)` → `DELETE /torrents/delete/{id}`
- `list_torrents(offset, limit, filter_active)` → `GET /torrents`
- `get_instant_availability(hashes)` → `GET /torrents/instantAvailability/{hashes}`
- `get_available_hosts()` → `GET /torrents/availableHosts`
- `unrestrict_link(link, remote=0)` → `POST /unrestrict/link`, returns `UnrestrictLink`
- `get_user()` → `GET /user`

**Error handling:**
- `RealDebridAPIError` — wraps HTTP status + error message
- `RealDebridOAuthError` — wraps OAuth flow failures
- Rate limit (429) → exponential backoff with jitter, up to 3 retries
- `TorrentInfo` has convenience properties: `is_complete`, `is_downloading`, `is_error`, `is_waiting_selection`

---

## Phase 3: Torrent Search Service `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/information_handlers/torrent_models.py` — `TorrentResult`, `TorrentSearchResponse` dataclasses
- `warp_mediacenter/backend/information_handlers/torrent_search.py` — `TorrentSearchService` class

**`TorrentResult` model:**
- `name`, `magnet`, `hash`, `seeders`, `leechers`, `size`, `size_bytes`, `source_site`, `quality`, `is_cached`, `uploader`, `date`, `match_score`

**`TorrentSearchResponse` model:**
- `cached: List[TorrentResult]`, `uncached: List[TorrentResult]`, `query`, `media_type`, `total_results`
- `all_results` property, `to_dict()` serialization method

**Search flow:**
1. Build query: `"{title} {year}"` for movies, `"{title} S{season:02d}E{episode:02d}"` for episodes
2. `GET {torrent_api_url}/api/v1/all/search?query={query}&limit={max_results}`
3. Add `X-API-Key` header if `api_key` configured
4. Parse response, extract magnet links and hashes
5. **Instant availability check:** Batch all hashes → `GET /torrents/instantAvailability/{hash1}/{hash2}/...`
6. Mark results with `is_cached=True` if RD has them
7. Filter: min seeders threshold, preferred quality keywords
8. Rank: `fuzzy_score(name, query) * 0.6 + (seeders / max_seeders) * 0.4`
9. Split into `cached_results` and `uncached_results`
10. Return `TorrentSearchResponse(cached=[...], uncached=[...])`

**Helper functions:**
- `_parse_size_bytes(size_str)` → converts "1.6 GB" to bytes
- `_extract_quality(name)` → extracts "1080p", "720p", "BluRay", etc. from torrent name
- `_fuzzy_score(torrent_name, query)` → `thefuzz` token_sort + partial ratio, returns 0.0-1.0

**Dependencies:** `thefuzz` (fuzzy matching), `requests` (HTTP)

---

## Phase 4: DB Integration — Local Availability Check + Episode Resolution `[x]`

**Status: COMPLETE**

**Files modified:**
- `warp_mediacenter/backend/persistence/sqlite.py` — added 4 new functions + updated `__all__`

**New functions:**
- `has_local_source(connection, tmdb_id, media_type, season?, episode?)` → bool
  - For movies: checks if title has any local source with `status='available'`
  - For TV: checks if the specific episode exists and title has local sources
- `get_title_by_tmdb_with_sources(connection, tmdb_id)` → dict | None
  - Returns title row plus `has_local_source`, `source_count`, `source_types`
- `get_title_seasons_episodes(connection, tmdb_id)` → list[dict]
  - Returns flattened episode list with `episode_id`, `season`, `episode`, `name`, `air_date`, `has_local_source`
- `get_episode_season_episode(connection, tmdb_id, season, episode)` → tuple | None
  - Returns `(title_name, season, episode)` for episode-level torrent search query building

**Flow:**
1. User clicks movie → check `has_local_source(tmdb_id, "movie")` → if yes, play local
2. User clicks series poster → UI fetches `get_title_seasons_episodes(tmdb_id)` → shows flattened episode list
3. User clicks episode → check `has_local_source(tmdb_id, "tv", season, episode)` → if no, trigger torrent search with `S{season:02d}E{episode:02d}` appended

---

## Phase 5: Torrent Stream Orchestrator (Bundled Module) `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/player/torrent_stream.py` — `TorrentStreamOrchestrator` class

**Class design:**
```python
class TorrentStreamOrchestrator:
    def __init__(self, search_service, debrid_client, playback_service)
    def search_and_resolve(title, media_type, tmdb_id, season?, episode?, year?, limit?) -> TorrentSearchResponse
    def play_selected(torrent, title, media_type, season?, episode?, year?) -> str
    def get_download_status(torrent_id) -> dict
    def list_active_torrents() -> dict
    def clear_completed() -> int
```

**`play_selected` flow:**
1. `debrid_client.add_magnet(torrent.magnet)` → torrent_id
2. Track torrent in `_active_torrents` dict
3. `debrid_client.select_files(torrent_id)` → starts download
4. `debrid_client.wait_for_download(torrent_id, timeout=300)` → polls every 2s
5. `debrid_client.get_torrent_info(torrent_id)` → extract streamable URL via `_extract_stream_url()`
6. `playback_service.play(source=url, is_stream=True, title=title, media_kind=media_type, season=season, episode=episode)`
7. Return URL for UI tracking

**`_extract_stream_url()` logic:**
- Prioritizes video file extensions (.mp4, .mkv, .avi, .mov, .webm, .m4v, .ts, .m3u8)
- Falls back to first link if no video extension found

**Status tracking:**
- `_active_torrents` dict tracks all torrents with metadata
- `get_download_status()` returns progress, speed, seeders, status message
- `list_active_torrents()` returns all tracked torrents with latest status
- `clear_completed()` removes finished/errored torrents from tracking

---

## Phase 6: PlaybackService Stream Support + Trakt Scrobble Integration `[x]`

**Status: COMPLETE**

**Files modified:**
- `warp_mediacenter/backend/player/service.py` — added trakt_manager, scrobble methods, source_type tracking

**Changes to `PlaybackService`:**
- Added `trakt_manager: Optional[TraktManager]` to `__init__`
- Added `tmdb_id`, `media_payload`, `show_payload`, `source_type` parameters to `play()`
- Added `_setup_scrobble_context()` — prepares scrobble media/show payload from TMDb data
- Added `_clear_scrobble_context()` — resets scrobble state after playback ends
- Added `_scrobble_start()` — fires on play start (progress=0)
- Added `_scrobble_pause()` — fires on pause with current progress %
- Added `_scrobble_stop(progress?)` — fires on stop/EndReached (progress=100% on EndReached)
- Added `_execute_scrobble(action, progress)` — wrapped with error handling
- Added `_get_progress_percent()` — calculates position/duration * 100
- `_on_player_state_change()` fires `_scrobble_stop(progress=100)` on `EndReached`
- `pause()` fires `_scrobble_pause()` before recording playback
- `stop()` fires `_scrobble_stop()` before recording playback

**Error handling:**
- No Trakt manager → skip silently
- No valid Trakt token → skip silently, log warning
- No scrobble media context → skip silently
- `TraktScrobbleConflict` (409) → catch, log debug, don't retry
- Other exceptions → catch, log warning, don't crash playback

**Edge cases handled:**
- Debrid streams without TMDb ID → skip scrobble, only update DB
- Movies use `media_payload` directly; episodes use `media_payload` + `show_payload`
- Scrobble context cleared on stop/EndReached to prevent stale state

---

## Phase 7: Minimal FastAPI Layer with SSE `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/api/__init__.py` — module init
- `warp_mediacenter/backend/api/app.py` — `create_app()` factory with lifespan, route registration
- `warp_mediacenter/backend/api/routes/__init__.py` — routes module init
- `warp_mediacenter/backend/api/routes/torrent.py` — SSE endpoint + status endpoints
- `warp_mediacenter/backend/api/routes/stream.py` — HTTP range request streaming + remote proxy
- `warp_mediacenter/backend/api/routes/images.py` — artwork serving

**SSE endpoint (`GET /api/v1/torrent/status/{torrent_id}/events`):**
- Streams JSON events every 2 seconds until torrent is complete/error/dead/unknown
- Headers: `Cache-Control: no-cache`, `Connection: keep-alive`, `X-Accel-Buffering: no`
- Uses `set_orchestrator()` to inject `TorrentStreamOrchestrator` instance

**Torrent status endpoints:**
- `GET /api/v1/torrent/status/{torrent_id}` — single torrent status
- `GET /api/v1/torrent/active` — list all tracked torrents
- `POST /api/v1/torrent/active/clear` — remove completed/errored torrents

**Stream endpoints:**
- `GET /api/v1/stream/{source_id}` — local file streaming with HTTP range support (206 Partial Content)
- `GET /api/v1/stream/remote?url=...` — proxy remote URLs (RealDebrid) with range support
- 1MB chunk size for streaming, auto content-type detection

**Image endpoints:**
- `GET /api/v1/images/tmdb/{tmdb_id}/{image_type}` — serve cached TMDb poster/backdrop
- `GET /api/v1/images/path/{path}` — serve image by filesystem path
- Cache-Control: `public, max-age=86400`

**Health check:**
- `GET /api/v1/health` — returns `{"status": "ok", "service": "warp-mediacenter"}`

---

## Phase 8: CLI Commands for Testing `[x]`

**Status: COMPLETE**

**Files modified:**
- `warp_mediacenter/cli/media.py` — added torrent/debrid/scrobble handlers and subparsers
- `warp_mediacenter/backend/persistence/__init__.py` — added Phase 4 function exports

**New subcommands:**
```
media torrent auth                          # Start RealDebrid OAuth2 device flow
media torrent search "Inception" --media-type movie --year 2010
media torrent search "Breaking Bad" --media-type tv --season 2 --episode 5
media torrent play "Inception" --media-type movie  # Full flow: search → prompt select → resolve → play
media torrent status                        # Show active RD torrents
media torrent cache-check "hash1,hash2"     # Check instant availability for hashes
media debrid auth                           # Start RealDebrid OAuth2 device flow
media debrid complete <device_code>         # Complete OAuth flow
media debrid status                         # Show RD account info
media scrobble status                       # Show Trakt scrobble auth status
media scrobble user                         # Show authenticated Trakt user profile
media scrobble resume --media-type movie    # Show playback resume entries
```

---

## Phase 9: Caching + Error Handling + Resilience `[x]`

**Status: COMPLETE**

**Schema v4 additions (`sqlite.py`):**
- Added `_SCHEMA_VERSION = 4` with `_apply_v4()` migration
- Created `torrent_cache` table — stores search results with TTL (1 hour default)
- Created `debrid_magnet_map` table — persists magnet hash → RD torrent_id mapping

**Cache helper functions (`sqlite.py`):**
- `cache_torrent_search()` — stores search results with TTL
- `get_cached_torrent_search()` — returns cached results if still valid
- `clear_expired_torrent_cache()` — removes expired entries
- `upsert_debrid_magnet_map()` — stores magnet hash → torrent_id mapping
- `get_debrid_torrent_id()` — looks up cached torrent ID

**TorrentSearchService caching:**
- `_get_cached_results()` — checks DB cache before fetching
- `_cache_results()` — stores results after successful fetch
- `_rebuild_response()` — reconstructs TorrentSearchResponse from cached JSON

**RealDebridClient magnet hash mapping:**
- `_extract_magnet_hash()` — extracts info hash from magnet link
- `_get_cached_torrent_id()` — looks up cached torrent ID
- `_store_magnet_map()` — persists magnet → torrent_id mapping
- `add_magnet()` now checks cache first, verifies torrent still exists before reusing

**TorrentStreamOrchestrator auto-retry:**
- `play_best_match(torrents, max_attempts=3)` — tries torrents in ranked order until one succeeds
- Logs each attempt and failure, raises aggregated error if all fail

---

## Phase 10: Trakt Scrobbling Integration (Detailed) `[x]`

**Status: COMPLETE**

**Files modified:**
- `warp_mediacenter/backend/player/controller.py` — added `trakt_manager` param, updated `PlayRequest` with scrobble fields
- `warp_mediacenter/backend/api/app.py` — registered scrobble router
- `warp_mediacenter/backend/api/routes/scrobble.py` — new scrobble status/user/resume endpoints
- `warp_mediacenter/cli/media.py` — added scrobble CLI commands

**PlayerController updates:**
- Added `trakt_manager: Optional[TraktManager]` to `__init__`
- Passed to `PlaybackService(trakt_manager=trakt_manager)`
- `PlayRequest` now includes `tmdb_id`, `media_payload`, `show_payload`, `source_type`
- `play()` passes all scrobble fields to `PlaybackService.play()`

**Scrobble API endpoints:**
- `GET /api/v1/scrobble/status` — returns Trakt auth status (authenticated, expires_at, reason)
- `GET /api/v1/scrobble/user` — returns authenticated user profile
- `GET /api/v1/scrobble/resume?media_type=movie&limit=25` — returns playback resume entries

**Complete scrobble flow (wired in Phase 6, finalized here):**
1. `play()` → `_scrobble_start()` with progress=0
2. `pause()` → `_scrobble_pause()` with current progress %
3. `stop()` → `_scrobble_stop()` with calculated progress %
4. `EndReached` → `_scrobble_stop(progress=100)` marks as completed
5. DB `record_playback()` fires alongside each scrobble call
6. For debrid/torrent streams: `tmdb_id` + `media_payload` passed via `PlayRequest` → scrobble context built from payload

---

## Phase 11: API Infrastructure (Middleware + DI) `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/api/middleware/__init__.py` — middleware package exports
- `warp_mediacenter/backend/api/middleware/cors.py` — CORS middleware configuration
- `warp_mediacenter/backend/api/middleware/error_handler.py` — uniform error handling middleware
- `warp_mediacenter/backend/api/middleware/request_logging.py` — request logging middleware
- `warp_mediacenter/backend/api/middleware/container.py` — dependency injection container

**Files modified:**
- `warp_mediacenter/backend/api/app.py` — wired middleware, enhanced health check
- `warp_mediacenter/backend/api/routes/torrent.py` — uses container for orchestrator
- `warp_mediacenter/backend/api/routes/scrobble.py` — uses container for trakt_manager

**CORS middleware (`cors.py`):**
- `setup_cors(app, allow_origins, allow_methods, allow_headers, ...)`
- Defaults: `origins=["*"]`, methods=`GET,POST,PUT,DELETE,OPTIONS,PATCH`
- Exposes: `Content-Range`, `Content-Length`, `Accept-Ranges`
- Configurable per-environment

**Error handler (`error_handler.py`):**
- `ErrorHandlerMiddleware` — catches all unhandled exceptions
- Returns uniform JSON: `{"error": true, "code": N, "message": "...", "path": "...", "timestamp": N}`
- Handles `HTTPException` (passes through status code)
- Handles `RequestValidationError` (422 with details)
- Logs all 500s with full traceback

**Request logging (`request_logging.py`):**
- `RequestLoggingMiddleware` — logs every request
- Fields: method, path, status_code, duration_ms
- Uses structured logging format

**Service container (`container.py`):**
- `ServiceContainer` dataclass — holds all shared services
- Fields: `torrent_orchestrator`, `debrid_client`, `player_controller`, `playback_service`, `trakt_manager`, `information_providers`, `torrent_search_service`
- `get_container()` / `set_container()` / `init_container()` — global access
- Routes use `_get_from_container_or_fallback()` pattern for backward compatibility

**Enhanced health check (`app.py`):**
- `GET /api/v1/health` returns:
  - `status`: "ok" | "degraded"
  - `subsystems.database`: schema_version, status
  - `subsystems.services`: list of registered services with status

---

## Phase 12: Library & Catalog API `[x]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/backend/api/routes/library.py` — library CRUD routes

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/library/movies` | List movies with pagination |
| GET | `/api/v1/library/shows` | List shows with pagination |
| GET | `/api/v1/library/recent` | Recently added titles |
| GET | `/api/v1/library/title/{id}` | Title details (movie or show) |
| GET | `/api/v1/library/title/{id}/episodes` | Episodes for a show |
| GET | `/api/v1/library/title/{id}/sources` | Sources for a title |
| GET | `/api/v1/library/sections` | List library sections |
| GET | `/api/v1/library/sections/{id}` | Section details |
| GET | `/api/v1/library/search` | Search local library |

**Query parameters:**
- `movies`, `shows`, `recent`: `?limit=50&offset=0`
- `search`: `?q=query&limit=20`
- `episodes`: `?season=1` (optional filter)

**Response format:**
```json
{
  "items": [...],
  "total": 123,
  "limit": 50,
  "offset": 0,
  "has_next": true
}
```

**Implementation notes:**
- Uses existing `sqlite.py` functions: `list_titles`, `search_titles`, `get_recently_added`, `get_title_by_id`, `get_episodes_for_title`, `get_sources_for_title`, `list_library_sections`
- Wraps results in pagination envelope
- Title details include source availability info via `get_title_by_tmdb_with_sources`

---

## Phase 13: Discovery & Search API `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/backend/api/routes/discovery.py` — discovery and search routes

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/search/tmdb` | Search TMDb (movies + shows) |
| GET | `/api/v1/search/trakt` | Search Trakt |
| GET | `/api/v1/search/unified` | Unified search (local + TMDb + Trakt) |
| GET | `/api/v1/catalog/tmdb/{category}` | TMDb catalogs (trending, popular, etc.) |
| GET | `/api/v1/catalog/trakt/{category}` | Trakt catalogs |
| GET | `/api/v1/catalog/continue-watching` | Continue watching widget |
| GET | `/api/v1/catalog/public-domain` | Public domain sources |

**Query parameters:**
- `search/tmdb`: `?q=query&type=movie|show&page=1`
- `search/trakt`: `?q=query&type=movie|show&limit=10`
- `search/unified`: `?q=query&limit=10` (searches all sources, deduplicates by TMDb ID)
- `catalog/tmdb`: `?category=trending|popular|top_rated&page=1`
- `catalog/trakt`: `?category=trending|popular|anticipated&period=daily|weekly|monthly`
- `continue-watching`: `?movie_limit=25&show_limit=25`

**Implementation notes:**
- Uses `InformationProviders` facade for all provider calls
- `unified` search merges results from local DB, TMDb, and Trakt
- Catalog endpoints use widget caching for Trakt catalogs
- `continue-watching` uses `get_trakt_continue_watching()` with in-memory cache

---

## Phase 14: Player Control + Subtitle API `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/api/routes/player.py` — player control routes (13 endpoints)
- `warp_mediacenter/backend/api/routes/subtitles.py` — subtitle search/download routes (6 endpoints)

**Files modified:**
- `warp_mediacenter/backend/api/app.py` — registered player and subtitles routers

**Player endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/player/play` | Start playback |
| POST | `/api/v1/player/pause` | Pause playback |
| POST | `/api/v1/player/resume` | Resume playback |
| POST | `/api/v1/player/stop` | Stop playback |
| POST | `/api/v1/player/seek` | Seek to position (ms) |
| POST | `/api/v1/player/volume` | Set volume (0-100) |
| POST | `/api/v1/player/mute` | Toggle mute |
| POST | `/api/v1/player/rate` | Set playback rate (0.25-4.0) |
| GET | `/api/v1/player/status` | Player status |
| GET | `/api/v1/player/status/events` | SSE player events |
| GET | `/api/v1/player/playlist` | Current playlist |
| POST | `/api/v1/player/next` | Play next |
| POST | `/api/v1/player/previous` | Play previous |

**Subtitle endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/subtitles/search` | Search OpenSubtitles/Podnapisi |
| POST | `/api/v1/subtitles/download` | Download subtitle file |
| POST | `/api/v1/subtitles/load` | Load subtitle into active playback |
| GET | `/api/v1/subtitles/active` | List active subtitles |
| DELETE | `/api/v1/subtitles/{id}` | Delete subtitle file |
| POST | `/api/v1/subtitles/cleanup` | Clean up all temp subtitles |

**Implementation notes:**
- Player routes use `player_controller` from service container
- SSE player events stream state changes (playing, paused, stopped, idle)
- Subtitle search uses existing `SubtitleService` (OpenSubtitles + Podnapisi)
- Downloaded subtitles tracked in `_temp_subtitles` dict, cleaned up via `/cleanup`
- `load` command passes subtitle file path to VLC adapter via `load_subtitle_file()`
- Thin client renders subtitles (ExoPlayer); server provides file paths

---

## Phase 15: Torrent Stream API (Enhanced) `[x]`

**Status: COMPLETE**

**Files modified:**
- `warp_mediacenter/backend/api/routes/torrent.py` — added search + resolve endpoints

**New endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/torrent/search` | Search torrents for a title |
| POST | `/api/v1/torrent/resolve` | Resolve torrent to stream URL |

**Existing endpoints (already implemented):**
- `GET /api/v1/torrent/status/{torrent_id}` — single torrent status
- `GET /api/v1/torrent/status/{torrent_id}/events` — SSE progress events
- `GET /api/v1/torrent/active` — list all tracked torrents
- `POST /api/v1/torrent/active/clear` — remove completed/errored torrents

**Request bodies:**
- `search`: `{"query": "Inception", "media_type": "movie", "tmdb_id": "550", "season": null, "episode": null, "year": 2010, "limit": 20}`
- `resolve`: `{"torrent_hash": "...", "title": "Inception", "media_type": "movie", "tmdb_id": "550", "season": null, "episode": null}`

**Response format (search):**
```json
{
  "cached": [...],
  "uncached": [...],
  "query": "Inception 2010",
  "media_type": "movie",
  "total_results": 42
}
```

**Response format (resolve):**
```json
{
  "torrent_id": "rd_torrent_id",
  "status": "waiting",
  "selected_file": "Inception.2010.1080p.BluRay.x264.mkv",
  "message": "Torrent added. Poll /status/{torrent_id}/events for progress."
}
```

**Implementation notes:**
- Uses `TorrentSearchService` via orchestrator for search
- Uses `RealDebridClient` for resolve (add magnet, select files)
- Returns immediately with torrent_id; client polls SSE for progress
- Helper functions: `_torrent_result_to_dict()`, `_get_debrid_client()`

---

## Phase 16: Trakt + RealDebrid API `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/api/routes/trakt.py` — Trakt OAuth + data routes (9 endpoints)
- `warp_mediacenter/backend/api/routes/debrid.py` — RealDebrid OAuth + torrent routes (12 endpoints)

**Files modified:**
- `warp_mediacenter/backend/api/app.py` — registered trakt and debrid routers

**Trakt endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/trakt/auth/start` | Start OAuth device flow |
| POST | `/api/v1/trakt/auth/complete` | Complete with device code |
| GET | `/api/v1/trakt/auth/status` | Auth status |
| GET | `/api/v1/trakt/history` | Watch history |
| GET | `/api/v1/trakt/lists` | User lists |
| GET | `/api/v1/trakt/lists/{id}/items` | List items |
| GET | `/api/v1/trakt/recommendations` | Recommendations |
| GET | `/api/v1/trakt/collection` | Collection |
| GET | `/api/v1/trakt/watchlist` | Watchlist |

**RealDebrid endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/debrid/auth/start` | Start OAuth device flow |
| POST | `/api/v1/debrid/auth/complete` | Complete with device code |
| GET | `/api/v1/debrid/auth/status` | Auth status |
| GET | `/api/v1/debrid/account` | Account info |
| POST | `/api/v1/debrid/magnet/add` | Add magnet link |
| GET | `/api/v1/debrid/torrent/{id}` | Torrent status |
| GET | `/api/v1/debrid/torrent/{id}/files` | Torrent file list |
| POST | `/api/v1/debrid/torrent/{id}/select` | Select files |
| DELETE | `/api/v1/debrid/torrent/{id}` | Delete torrent |
| GET | `/api/v1/debrid/torrents` | List torrents |
| GET | `/api/v1/debrid/stream/{torrent_id}/{file_id}` | Get streamable URL |
| GET | `/api/v1/debrid/cache/check` | Instant availability check |

**Implementation notes:**
- Trakt routes use `TraktManager` from container
- RealDebrid routes use `RealDebridClient` from container
- OAuth flows return `user_code` + `verification_url` for thin client display
- `debrid/stream` extracts streamable URL from torrent file info
- `cache/check` accepts comma-separated hashes via query param
- Helper functions: `_get_trakt()`, `_get_debrid()`, `_catalog_item_to_dict()`

---

## Phase 17: Settings & Management API `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/api/routes/settings.py` — settings + management routes (7 endpoints)

**Files modified:**
- `warp_mediacenter/backend/api/app.py` — registered settings router

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/settings` | Get all settings |
| PUT | `/api/v1/settings/{key}` | Update setting |
| GET | `/api/v1/settings/providers` | Provider status |
| POST | `/api/v1/settings/library/scan` | Trigger library scan |
| GET | `/api/v1/settings/library/scan/status` | Scan progress |
| GET | `/api/v1/settings/trailers/movie/{id}` | Movie trailers |
| GET | `/api/v1/settings/trailers/show/{id}` | Show trailers |

**Request bodies:**
- `settings/{key}`: `{"value": "..."}`
- `library/scan`: `{"paths": ["/path/to/media"], "section_id": null, "incremental": true}`

**Response format (providers):**
```json
{
  "tmdb": {"status": "ok", "api_key_configured": true},
  "trakt": {"status": "ok", "authenticated": true, "api_key_configured": true},
  "realdebrid": {"status": "ok", "authenticated": true, "api_key_configured": true},
  "torrent_api": {"status": "ok", "url": "http://localhost:8009", "api_key_configured": true}
}
```

**Implementation notes:**
- Settings use existing `get_setting` / `set_setting` from `sqlite.py`
- Provider status checks each manager's authentication state
- Library scan uses existing `scan_once()` from `backend/library/scanner.py`
- Scan runs in background thread, status tracked via `_scan_status` dict with thread lock
- Trailers use `TrailersManager` via `InformationProviders` facade
- Scan status: `{"running": bool, "progress": int, "message": str, "result": dict}`

---

## Phase 18: API Server Entry Point `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/cli/api_server.py` — Service initialization and uvicorn startup

**Files modified:**
- `warp_mediacenter/cli/media.py` — added `serve` subcommand
- `warp_mediacenter/backend/common/logging.py` — added `StructuredLogger` for kwargs support

**CLI command:**
```
media serve                          # Start API server on 0.0.0.0:8000
media serve --host 127.0.0.1 --port 9000
media serve --log-level debug --reload
```

**Service wiring:**
1. `InformationProviders` — TMDb, Trakt, public archives, trailers
2. `RealDebridClient` — OAuth2, torrent management
3. `TorrentSearchService` — Torrent-API-Py search + ranking
4. `SubtitleService` — OpenSubtitles, Podnapisi, etc.
5. `PlayerController` — VLC (desktop) or HTTPAdapter (thin_client fallback)
6. `TorrentStreamOrchestrator` — Search → Debrid → Playback pipeline
7. All wired into `ServiceContainer` and route module globals

**Features:**
- Auto-detects VLC availability, falls back to thin_client mode
- Graceful shutdown via SIGINT/SIGTERM
- Prints startup banner with local/network URLs
- All 77 API routes available immediately
- `--reload` flag for development

---

## Phase 19: Torrent-API-Py Bundling `[x]`

**Status: COMPLETE**

**Files created:**
- `warp_mediacenter/backend/common/service_manager.py` — Subprocess manager for external services
- `warp_mediacenter/cli/warp_startup.py` — Two-layer startup (Torrent-API-Py + API server)

**Files modified:**
- `warp_mediacenter/cli/media.py` — added `warp-startup` CLI command

**CLI commands:**
```
media serve                # Start API server only
media warp-startup         # Start Torrent-API-Py + API server together
media warp-startup --reload  # Dev mode (skips Torrent-API-Py)
```

**ServiceManager features:**
- `start()` — Launches subprocess with piped stdout/stderr
- `wait_for_health()` — Polls health URL until ready or timeout
- `stop()` — Graceful terminate → kill after 5s timeout
- `is_running` — Check if process is alive

**TorrentApiPyManager features:**
- Auto-detects executable from PATH or common locations
- Configurable host/port via CLI args
- Health check at `http://{host}:{port}/api/v1/health`
- Graceful fallback if executable not found (warns, continues)

**warp-startup flow:**
1. Initialize logging
2. Start Torrent-API-Py subprocess (skip if `--reload`)
3. Wait for Torrent-API-Py health check (30s timeout)
4. Initialize all backend services
5. Start API server on main thread
6. Graceful shutdown on Ctrl+C stops both services

---

## Dependency Graph & Build Order

```
Phase 1-10 (Torrent-to-Stream Pipeline) ──────────────────────────────────────┐
Phase 11 (API Infrastructure) ◄───────────────────────────────────────────────┤── after 1-10
Phase 12 (Library & Catalog) ◄────────────────────────────────────────────────┤
Phase 13 (Discovery & Search) ◄───────────────────────────────────────────────┤
Phase 14 (Player + Subtitles) ◄───────────────────────────────────────────────┤
Phase 15 (Torrent Stream API) ◄───────────────────────────────────────────────┤
Phase 16 (Trakt + RealDebrid API) ◄───────────────────────────────────────────┤
Phase 17 (Settings & Management) ◄────────────────────────────────────────────┘
```

**Recommended build order:**
11 → 12 → 13 → 14 → 15 → 16 → 17

---

## Progress Summary

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Settings Module | `[x]` COMPLETE |
| 2 | RealDebrid OAuth2 Client | `[x]` COMPLETE |
| 3 | Torrent Search Service | `[x]` COMPLETE |
| 4 | DB Integration | `[x]` COMPLETE |
| 5 | Torrent Stream Orchestrator | `[x]` COMPLETE |
| 6 | PlaybackService + Scrobble | `[x]` COMPLETE |
| 7 | FastAPI + SSE | `[x]` COMPLETE |
| 8 | CLI Commands | `[x]` COMPLETE |
| 9 | Caching + Resilience | `[x]` COMPLETE |
| 10 | Trakt Scrobble Complete | `[x]` COMPLETE |
| 11 | API Infrastructure (Middleware + DI) | `[x]` COMPLETE |
| 12 | Library & Catalog API | `[x]` COMPLETE |
| 13 | Discovery & Search API | `[x]` COMPLETE |
| 14 | Player Control + Subtitle API | `[x]` COMPLETE |
| 15 | Torrent Stream API (Enhanced) | `[x]` COMPLETE |
| 16 | Trakt + RealDebrid API | `[x]` COMPLETE |
| 17 | Settings & Management API | `[x]` COMPLETE |
| 18 | API Server Entry Point | `[x]` COMPLETE |
| 19 | Torrent-API-Py Bundling | `[x]` COMPLETE |
| 20 | PySide6 Foundation & App Shell | `[ ]` NOT STARTED |
| 21 | Catalog Widget System (Core UX) | `[ ]` NOT STARTED |
| 22 | Movies Tab | `[ ]` NOT STARTED |
| 23 | Shows Tab | `[ ]` NOT STARTED |
| 24 | Media Detail & Playback Flow | `[ ]` NOT STARTED |
| 25 | Local Drive Tab | `[ ]` NOT STARTED |
| 26 | Settings Tab | `[ ]` NOT STARTED |
| 27 | Auth Flows (Trakt + RealDebrid) | `[ ]` NOT STARTED |
| 28 | Power Tab | `[ ]` NOT STARTED |
| 29 | Search & Discovery | `[ ]` NOT STARTED |
| 30 | Polish & Integration | `[ ]` NOT STARTED |

---

## Phase 20: PySide6 Foundation & App Shell `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/__init__.py` — UI package init
- `warp_mediacenter/ui/__main__.py` — Entry point (`python -m warp_mediacenter.ui`)
- `warp_mediacenter/ui/app.py` — QApplication setup, event loop integration
- `warp_mediacenter/ui/main_window.py` — Main window with tab bar
- `warp_mediacenter/ui/theme.py` — Arctic Horizon 2 QSS theme
- `warp_mediacenter/ui/api/__init__.py` — API client package
- `warp_mediacenter/ui/api/client.py` — Async API client (aiohttp + QThread)
- `warp_mediacenter/ui/api/cache.py` — Image cache (disk + memory)

**Files to modify:**
- `requirements.txt` — add `PySide6>=6.6.0`
- `warp_mediacenter/cli/media.py` — add `media ui` command

**Features:**
- `WarpApp` class — QApplication subclass with event loop integration
- `MainWindow` — Full-screen window (1920x1080 optimized, scalable)
- Top tab bar: **Movies**, **Shows**, **Local Drive**, **Settings**, **Power**
- Arctic Horizon 2 dark theme via QSS (dark backgrounds, accent colors, rounded corners)
- `ApiClient` — Thread-safe async HTTP client using aiohttp + QThread
  - Base URL configurable (default: `http://localhost:8000`)
  - Methods: `get()`, `post()`, `put()`, `delete()` with error handling
  - Retry logic for transient failures
- `ImageCache` — Download and cache posters/backdrops
  - Memory cache (LRU, max 100 images)
  - Disk cache (`~/.warp-mediacenter/cache/images/`)
  - Methods: `get_poster(tmdb_id, type)`, `get_backdrop(tmdb_id)`, `get_url(url)`
  - Async download with progress callback
- Keyboard navigation framework:
  - Arrow keys (left/right/up/down) for focus movement
  - Enter/Return for selection
  - Escape for back/close
  - `/` for search
  - `?` for help overlay
- Loading spinner overlay (centered, semi-transparent background)
- Error toast notifications (bottom-right, auto-dismiss after 5s)

**Theme design (Arctic Horizon 2 style):**
- Background: `#1a1a2e` (deep dark blue)
- Card background: `#16213e` (slightly lighter)
- Accent: `#e94560` (red/coral for focus/highlights)
- Text primary: `#eaeaea` (near white)
- Text secondary: `#a0a0a0` (muted gray)
- Focus ring: `#e94560` with 2px border
- Rounded corners: 8px for cards, 12px for overlays
- Font: System default, 14px base, 18px headings

**CLI command:**
```
media ui                           # Launch desktop client
media ui --server http://localhost:8000  # Connect to specific server
```

---

## Phase 21: Catalog Widget System (Core UX) `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/widgets/__init__.py` — Widgets package init
- `warp_mediacenter/ui/widgets/catalog_widget.py` — Scrollable widget row
- `warp_mediacenter/ui/widgets/poster_card.py` — Individual poster with hover effects
- `warp_mediacenter/ui/widgets/metadata_overlay.py` — Title, synopsis, ratings overlay
- `warp_mediacenter/ui/widgets/backdrop_background.py` — Landscape backdrop background

**Features:**

**`CatalogWidget` (scrollable widget row):**
- Horizontal scrollable container with smooth animation
- 6 configurable widget layers per tab (scroll down to reveal next)
- Each layer fetches from a catalog endpoint (configurable via settings)
- Lazy loading: fetch posters as they come into view
- Auto-refresh on focus (optional, configurable TTL)
- Widget header: catalog name + "See All" button
- Empty state: "No items available" with retry button

**`PosterCard` (individual poster):**
- Portrait-oriented poster (2:3 aspect ratio, ~200x300px)
- Hover effects: scale up 1.05x, brightness increase
- Focus ring: 2px accent color border with glow
- Cached/uncached badge (green dot for local, orange for RD cached, gray for uncached)
- Title label below poster (truncated with ellipsis)
- Year/rating badge overlay (top-right corner)
- Click → open media detail view
- Keyboard focus: arrow keys move focus between cards

**`MetadataOverlay` (top half panel):**
- Appears when poster is hovered/focused
- Top 50% of screen, semi-transparent gradient background
- Displays:
  - Title (large, bold)
  - Year, runtime, certification
  - TMDb rating (star icon + score)
  - Trakt rating (percentage)
  - Synopsis (truncated to 3 lines, expandable)
  - Genre tags
  - "Play" button (primary action)
  - "More Info" button (opens full detail view)

**`BackdropBackground` (landscape backdrop):**
- Fills entire window background
- Changes on poster hover/focus with crossfade animation (300ms)
- Dark gradient overlay (bottom-to-top) for text readability
- Blurred version of backdrop image
- Falls back to solid dark color if no backdrop available

**Data flow:**
1. Tab loads → fetches catalog config from settings
2. For each widget layer → calls `/api/v1/catalog/{provider}/{category}`
3. For each item → downloads poster via `ImageCache`
4. On hover/focus → downloads backdrop via `ImageCache`
5. Metadata populated from API response

---

## Phase 22: Movies Tab `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/tabs/__init__.py` — Tabs package init
- `warp_mediacenter/ui/tabs/movies_tab.py` — Movies tab implementation

**Features:**
- 6 configurable catalog widget layers (default):
  1. TMDb Trending (daily)
  2. TMDb Popular
  3. TMDb Top Rated
  4. Trakt Trending
  5. Trakt Popular
  6. Trakt Anticipated
- Each widget fetches from `/api/v1/catalog/tmdb/{category}` or `/api/v1/catalog/trakt/{category}`
- Local source indicator: green dot on poster if movie exists in local library
- Click poster → `MediaDetailView` (Phase 24)
- Scroll down → reveals next widget layer
- Keyboard navigation: left/right within row, up/down between rows
- "Refresh" button to reload all widgets
- Loading state: skeleton cards while fetching

**Catalog configuration (via Settings tab, Phase 26):**
- User can enable/disable individual widgets
- User can reorder widgets
- User can change catalog category per widget
- Config persisted via `/api/v1/settings/{key}`

---

## Phase 23: Shows Tab `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/tabs/shows_tab.py` — Shows tab implementation
- `warp_mediacenter/ui/widgets/episode_list.py` — Episode grid widget

**Features:**
- Same 6-layer catalog widget layout as Movies tab
- Default catalogs: TMDb Trending Shows, Popular Shows, Top Rated, Trakt Trending, Popular, Anticipated
- Click show poster → episode grid view
- Episode grid:
  - Season selector dropdown (top)
  - Episodes displayed as cards in a grid (4-6 columns)
  - Each card: episode number, name, air date, local source indicator
  - Click episode → play or torrent search
  - Keyboard navigation: arrow keys between episodes
- Episode data from `/api/v1/library/title/{id}/episodes?season=N`
- Local source check via `/api/v1/library/title/{id}/sources`

---

## Phase 24: Media Detail & Playback Flow `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/views/__init__.py` — Views package init
- `warp_mediacenter/ui/views/media_detail.py` — Full-screen media detail view
- `warp_mediacenter/ui/views/playback_view.py` — Playback view with VLC
- `warp_mediacenter/ui/dialogs/__init__.py` — Dialogs package init
- `warp_mediacenter/ui/dialogs/torrent_dialog.py` — Torrent search + selection dialog

**Features:**

**`MediaDetailView` (full-screen detail):**
- Backdrop background with dark gradient overlay
- Left side: large portrait poster
- Right side: metadata panel
  - Title, year, runtime, certification
  - TMDb + Trakt ratings
  - Synopsis (full, scrollable)
  - Genre tags
  - Cast list (top 5)
  - "Play" button (primary action)
  - "Trailer" button (if available)
  - Sources list (local files, debrid links)
- Bottom: related/similar movies (horizontal scroll)
- Keyboard: Escape to go back

**Playback flow:**
1. Click "Play" → check local sources via `/api/v1/library/title/{id}/sources`
2. If local source exists → play via VLC (Phase 24)
3. If no local source → open `TorrentDialog`
4. `TorrentDialog`:
   - Search torrents via `/api/v1/torrent/search`
   - Display cached vs uncached split
   - Each result: name, quality, seeders, size, cached badge
   - Select torrent → resolve via `/api/v1/torrent/resolve`
   - Poll SSE for download progress
   - Once ready → play stream URL via VLC
5. Trakt scrobble: start/pause/stop via API calls

**`PlaybackView` (VLC-based):**
- Embeds VLC via `python-vlc` (already in codebase)
- Controls: play/pause, seek bar, volume, fullscreen
- Subtitle management:
  - "Subtitles" button → opens subtitle search dialog
  - Search via `/api/v1/subtitles/search`
  - Download via `/api/v1/subtitles/download`
  - Load via `/api/v1/subtitles/load`
  - Active subtitles list with delete option
  - Cleanup on playback stop via `/api/v1/subtitles/cleanup`
- Keyboard shortcuts: space (play/pause), left/right (seek), up/down (volume), S (subtitles), F (fullscreen)
- Trakt scrobble integration:
  - `POST /api/v1/player/play` → scrobble start
  - `POST /api/v1/player/pause` → scrobble pause
  - `POST /api/v1/player/stop` → scrobble stop

---

## Phase 25: Local Drive Tab `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/tabs/local_drive_tab.py` — Local drive + library scan tab
- `warp_mediacenter/ui/widgets/file_browser.py` — File/folder picker widget

**Features:**
- File browser widget:
  - Navigate filesystem (tree view)
  - Select folders for library scan
  - Multi-select support
  - "Add Selected" button
- Library scan panel:
  - List of configured scan paths
  - "Scan Now" button → calls `POST /api/v1/settings/library/scan`
  - Progress indicator (polls `GET /api/v1/settings/library/scan/status`)
  - Scan results: new titles, updated titles, duration
- Library sections:
  - List existing sections from `GET /api/v1/library/sections`
  - Create new section with name + kind + paths
  - Edit/delete sections
- Browse local library:
  - Movies section → poster grid
  - Shows section → poster grid
  - Click poster → media detail view

---

## Phase 26: Settings Tab `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/tabs/settings_tab.py` — Settings panel
- `warp_mediacenter/ui/widgets/settings_form.py` — Settings form widget
- `warp_mediacenter/ui/widgets/catalog_config.py` — Catalog configuration widget
- `warp_mediacenter/ui/widgets/provider_status.py` — Provider status display

**Features:**
- **Catalog Configuration:**
  - Per-tab widget list (Movies, Shows)
  - Toggle enable/disable per widget
  - Drag-to-reorder (or up/down buttons)
  - Change catalog category via dropdown
  - "Reset to defaults" button
  - Save via `PUT /api/v1/settings/{key}`
- **Provider Status Panel:**
  - TMDb: status, API key configured (yes/no)
  - Trakt: status, authenticated (yes/no), token expiry
  - RealDebrid: status, authenticated (yes/no), account type
  - Torrent API: status, URL, API key configured
  - Refresh button → calls `GET /api/v1/settings/providers`
- **API Key Settings:**
  - TMDb API key input
  - Trakt client ID + client secret inputs
  - RealDebrid client ID + client secret inputs
  - Torrent API URL + API key inputs
  - Save button → calls `PUT /api/v1/settings/{key}`
- **Server Connection:**
  - API server host/port inputs
  - Test connection button → calls `GET /api/v1/health`
  - Auto-reconnect on change
- **General Settings:**
  - Image quality (thumbnail/original)
  - Cache size limit
  - Auto-refresh interval
  - Keyboard shortcuts reference

---

## Phase 27: Auth Flows (Trakt + RealDebrid) `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/dialogs/auth_dialog.py` — OAuth device flow dialog
- `warp_mediacenter/ui/widgets/auth_status.py` — Auth status indicator widget

**Features:**

**Trakt Auth:**
- "Connect Trakt" button → opens `AuthDialog`
- Dialog flow:
  1. Call `POST /api/v1/trakt/auth/start`
  2. Display: user_code (large, bold), verification_url (clickable)
  3. "I've authorized" button → polls `POST /api/v1/trakt/auth/complete`
  4. On success: show authenticated user profile, close dialog
  5. On timeout: show error, allow retry
- Status indicator in Settings tab:
  - Green: authenticated
  - Yellow: token expiring soon
  - Red: not authenticated / expired
  - Click → re-auth prompt

**RealDebrid Auth:**
- Same flow as Trakt, using `/api/v1/debrid/auth/*` endpoints
- Display account info on success (premium status, expiry date)
- Status indicator with account type (free/premium)

**Token Management:**
- Auto-refresh tokens before expiry
- Re-auth prompt on 401 errors
- Clear token button (logout)

---

## Phase 28: Power Tab `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/tabs/power_tab.py` — Server control + quit tab

**Features:**
- Server control panel:
  - API server status (running/stopped)
  - Start/Stop/Restart buttons
  - Torrent-API-Py status (running/stopped)
  - Start/Stop buttons for Torrent-API-Py
- System info:
  - Local IP address
  - API server URL
  - Torrent-API-Py URL
  - Application version
  - Uptime
- Actions:
  - "Open in Browser" → opens `http://localhost:8000/docs`
  - "Clear Cache" → clears image cache
  - "Quit" → graceful shutdown of all services + exit
- Keyboard: Enter on Quit button → confirmation dialog → exit

---

## Phase 29: Search & Discovery `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/views/search_view.py` — Search results view
- `warp_mediacenter/ui/widgets/search_bar.py` — Global search bar widget

**Features:**
- Global search bar:
  - Accessible from any tab via `/` key
  - Overlay at top of screen
  - Auto-complete suggestions (debounced, 300ms)
  - Search icon, clear button
  - Enter → execute search
  - Escape → close search
- Search execution:
  - Calls `GET /api/v1/search/unified?q={query}&limit=20`
  - Results displayed as poster grid
  - Each result shows source badge (local/TMDb/Trakt)
  - Keyboard navigation through results
  - Click result → media detail view
- Search history:
  - Last 10 searches stored in memory
  - Accessible via down arrow in search bar
  - Clear history button

---

## Phase 30: Polish & Integration `[ ]`

**Status: NOT STARTED**

**Files to create:**
- `warp_mediacenter/ui/__main__.py` — Entry point updates
- `warp_mediacenter/cli/media.py` — `media ui` command finalization

**Files to modify:**
- `requirements.txt` — final dependency list

**Features:**
- `media ui` CLI command:
  - `media ui` — Launch desktop client, auto-start local server
  - `media ui --server http://host:port` — Connect to existing server
  - `media ui --fullscreen` — Start in fullscreen mode
  - `media ui --windowed` — Start in windowed mode
- Auto-connect logic:
  - Try local server first (`http://localhost:8000`)
  - If not available → show connection dialog
  - Allow manual server URL input
- Keyboard shortcuts reference (accessible via `?` key):
  - Arrow keys: navigate
  - Enter/Return: select
  - Escape: back/close
  - `/`: search
  - `?`: help
  - `F`: fullscreen toggle
  - `S`: subtitles (during playback)
  - `Space`: play/pause (during playback)
  - `Left/Right`: seek (during playback)
  - `Up/Down`: volume (during playback)
- Smooth animations and transitions:
  - Crossfade for backdrop changes (300ms)
  - Scale animation for poster hover (150ms)
  - Slide-in for overlays (200ms)
  - Fade-in for loading states (100ms)
- Error handling:
  - All API failures show toast notification
  - Retry button on failed requests
  - Graceful degradation (show cached data if available)
  - Network error detection and reconnection
- Integration tests for UI flows (optional, if time permits)

---

## Architecture Overview

```
warp_mediacenter/ui/
  __init__.py
  __main__.py              # Entry point: python -m warp_mediacenter.ui
  app.py                   # QApplication setup, event loop integration
  main_window.py           # Main window with tab bar
  theme.py                 # Arctic Horizon 2 QSS theme

  api/
    __init__.py
    client.py              # Async API client (aiohttp + QThread)
    cache.py               # Image cache (disk + memory)

  widgets/
    __init__.py
    catalog_widget.py      # Scrollable widget row
    poster_card.py         # Individual poster with hover effects
    metadata_overlay.py    # Title, synopsis, ratings overlay
    backdrop_background.py # Landscape backdrop background
    episode_list.py        # Episode grid for shows
    file_browser.py        # File picker for library scan
    settings_form.py       # Settings form widget
    catalog_config.py      # Catalog configuration widget
    provider_status.py     # Provider status display
    auth_status.py         # Auth status indicator
    search_bar.py          # Global search bar

  tabs/
    __init__.py
    movies_tab.py          # Movies tab with catalog widgets
    shows_tab.py           # Shows tab with catalog widgets
    local_drive_tab.py     # Local drive + library scan
    settings_tab.py        # Settings panel
    power_tab.py           # Server control + quit

  views/
    __init__.py
    media_detail.py        # Media detail view
    playback_view.py       # Playback view with VLC
    search_view.py         # Search results view

  dialogs/
    __init__.py
    torrent_dialog.py      # Torrent search + selection
    auth_dialog.py         # Trakt + RealDebrid auth
```

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| PySide6 (not PyQt6) | LGPL license, official Qt binding |
| Pure Python widgets (not QML) | Maximum control over custom theming, easier to iterate |
| VLC playback via python-vlc | Already in codebase, full subtitle support, user has VLC installed |
| Original/high-res images from TMDb | Thin client renders, server/CDN handles bandwidth |
| aiohttp + QThread | Async API calls without blocking UI |
| Disk image cache | Fast loading on subsequent runs |
| Keyboard-first navigation | Kodi-style UX, remote-control friendly |
| Configurable catalogs via settings | User chooses which widgets to show |
| Browser fallback for streaming | If VLC fails, open system browser to stream URL |

## Dependency Graph & Build Order (Phases 20-30)

```
Phase 20 (Foundation) ────────────────────────────────────────────────────────┐
Phase 21 (Widget System) ◄────────────────────────────────────────────────────┤── after 20
Phase 22 (Movies Tab) ◄───────────────────────────────────────────────────────┤
Phase 23 (Shows Tab) ◄────────────────────────────────────────────────────────┤── after 21
Phase 24 (Detail + Playback) ◄────────────────────────────────────────────────┤── after 21
Phase 25 (Local Drive) ◄──────────────────────────────────────────────────────┤── after 20
Phase 26 (Settings) ◄─────────────────────────────────────────────────────────┤── after 20
Phase 27 (Auth Flows) ◄───────────────────────────────────────────────────────┤── after 26
Phase 28 (Power Tab) ◄────────────────────────────────────────────────────────┤── after 20
Phase 29 (Search) ◄───────────────────────────────────────────────────────────┤── after 20
Phase 30 (Polish) ◄────────────┬────────────┬────────────┬────────────────────┘── after 21-29
```

**Recommended build order:**
20 → 21 → 22 → 23 → 24 → 25 → 26 → 27 → 28 → 29 → 30

---

## Files Created/Modified Summary

### New files (Phases 1-11)
- `warp_mediacenter/config/settings/torrent.py`
- `warp_mediacenter/backend/player/debrid/__init__.py`
- `warp_mediacenter/backend/player/debrid/models.py`
- `warp_mediacenter/backend/player/debrid/oauth.py`
- `warp_mediacenter/backend/player/debrid/client.py`
- `warp_mediacenter/backend/information_handlers/torrent_models.py`
- `warp_mediacenter/backend/information_handlers/torrent_search.py`
- `warp_mediacenter/backend/player/torrent_stream.py`
- `warp_mediacenter/backend/api/__init__.py`
- `warp_mediacenter/backend/api/app.py`
- `warp_mediacenter/backend/api/routes/__init__.py`
- `warp_mediacenter/backend/api/routes/torrent.py`
- `warp_mediacenter/backend/api/routes/stream.py`
- `warp_mediacenter/backend/api/routes/images.py`
- `warp_mediacenter/backend/api/routes/scrobble.py`
- `warp_mediacenter/backend/api/middleware/__init__.py`
- `warp_mediacenter/backend/api/middleware/cors.py`
- `warp_mediacenter/backend/api/middleware/error_handler.py`
- `warp_mediacenter/backend/api/middleware/request_logging.py`
- `warp_mediacenter/backend/api/middleware/container.py`

### Modified files (Phases 1-11)
- `requirements.txt`
- `warp_mediacenter/config/settings/__init__.py`
- `warp_mediacenter/backend/persistence/sqlite.py`
- `warp_mediacenter/backend/persistence/__init__.py`
- `warp_mediacenter/backend/player/service.py`
- `warp_mediacenter/backend/player/controller.py`
- `warp_mediacenter/cli/media.py`
