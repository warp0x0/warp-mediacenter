# Catalog plugins

A **catalog** publishes browsable lists — trending, popular, by genre, by decade
— and returns the media in them. It owns no watch state and no playable streams;
those are the Tracker and Provider categories.

Catalog is a **non-exclusive** category. Every enabled catalog plugin contributes
lists at once, alongside the built-in TMDb source, and the user picks per home
row which list to show.

Reference implementations: [`plugins/simkl-catalog`](../../plugins/simkl-catalog)
and [`plugins/tvdb-catalog`](../../plugins/tvdb-catalog).

---

## The two things a catalog does

```
catalog.lists   ->  "here is every list I publish"
catalog.fetch   ->  "here is page N of list X"
```

Plus the optional `catalog.describe` and `catalog.cache.clear`, and the standard
`plugin.*` lifecycle and settings actions every plugin gets.

A plugin is one function:

```python
def handle(action: str, payload: dict, context: dict) -> dict: ...
```

declared in `plugin.json` as `"entrypoint": "my_catalog.main:handle"`.

## Manifest

```jsonc
{
  "manifest_version": 2,
  "id": "my-catalog",
  "name": "My Catalogs",
  "version": "1.0.0",
  "category": "catalog",
  "entrypoint": "my_catalog.main:handle",
  "icon": "grid_view_outlined",       // must be in _pluginIcon's allowlist
  "host_api": { "min": 1, "max": 1 },

  "capabilities": [
    "catalog.lists",
    "catalog.fetch",
    "catalog.paginate"                // omit if you only ever serve page 1
  ],

  "network": {
    "allowed_hosts": ["api.example.com"],
    "rate_limit": { "per_minute": 60 }
  },

  "auth": { "kind": "none" },
  "settings_ui": { "title": "My Catalogs" },

  "metadata": { "shadows": "trakt" }  // optional; see Shadowing
}
```

Capabilities are checked **before** dispatch. A plugin that does not declare
`catalog.paginate` is never asked for page 2, whatever its list definitions
claim — so a mis-declared list costs one short row rather than a fetch loop.

## `catalog.lists`

Returns every list, unconditionally — including when the plugin is not yet
configured. The user should be able to see what a plugin offers before deciding
to set it up; `catalog.fetch` is where a missing credential surfaces.

```python
ok({"lists": [
  {
    "id": "genre_horror",             # unique within this plugin
    "title": "Horror",
    "media_types": ["movie", "show"], # what it can actually serve
    "group": "genre",                 # standard|discover|genre|decade|network|other
    "description": "Scary things",
    "supports_pagination": True,
    "page_size": 60,                  # your natural upstream page size
    "params": {"sort": "popular-this-week"},
    "preserve_order": False,          # see below
  },
]})
```

`group` drives the picker's section headers. An unknown group still renders
(under its own uppercased name) rather than being dropped.

### `preserve_order`

The host applies a **daily shuffle** to each list, seeded by date and list id.
That is what gives browse rows day-to-day variety, since the underlying list
barely moves — the same six titles every morning otherwise.

Set `preserve_order: True` when the order *is* the information: a
recently-added list, a personal queue, anything sorted by recency or rank that
the user would notice being scrambled. (Continue Watching is the built-in
example — shuffling it would put a show finished last month above the episode
paused ten minutes ago.)

`params` is **opaque to the host**. It is stored in the user's widget config and
handed back verbatim on fetch, so a plugin can encode a genre slug or a sort
order without the host parsing strings. It must be JSON scalars — anything the
round trip cannot reproduce is stripped, because a param that comes back
different would silently change the row.

## `catalog.fetch`

**Page-based, not offset-based.** The host owns offsets: it keeps a day-scoped
pool per list and grows it by pulling successive pages. The plugin only ever
answers "give me page N".

```python
# payload
{"list_id": "genre_horror", "media_type": "movie",
 "params": {"sort": "popular-this-week"}, "page": 3, "page_size": 60}

# response
ok({"items": [...], "page": 3, "has_more": True, "total": 812})
```

`has_more` is authoritative. `total` is a best-effort hint and may be omitted —
many services report no count at all.

Two rules that matter more than they look:

- **Return `has_more: False` when you are done.** An empty page that still claims
  more would spin the host's growth loop. When asked for a page past the end, or
  for a media type a list does not serve, return an empty page — not an error.
- **Skip malformed entries, never fail the response.** One bad upstream record
  should cost that one card, not the user's whole row.

### Item shape

Deliberately thin. Ids and a title are enough:

```python
{
  "media": {
    "type": "movie",                 # movie|show
    "ids": {"tmdb": 603, "imdb": "tt0133093", "tvdb": 1234, "slug": "the-matrix"},
    "title": "The Matrix",
    "year": 1999,
  },
  # everything below is optional
  "overview": "...",
  "rating": 8.7,
  "genres": ["Action"],
  "artwork": {"poster": "https://...", "backdrop": "https://..."},
}
```

## Enrichment — what the host does for you

The host fills in what a plugin does not have, so a plugin that can only produce
the ids it natively holds still yields a fully-rendered row. Per fetched block:

1. **Resolve** — anything without a TMDb id gets one, via TMDb's `/find` on an
   IMDb or TVDB id, then falling back to a title+year search. TMDb id is the key
   the whole app navigates, caches and fetches artwork on. Rows that stay
   unresolvable are **dropped**: a tile that does nothing when clicked is worse
   than a shorter row.
2. **Enrich** — poster, backdrop, overview, rating and genres from TMDb, for any
   row without a poster.

So: return ids and a title. Supply `artwork` only when you have images you
actively want used — doing so skips step 2 for that row.

## Credentials

`auth.kind` is normally `"none"`: catalog lists are public, and OAuth belongs to
Tracker plugins. An app-level key still goes in plugin settings:

- **Bundle it** when the service issues keys per *app* — the Simkl plugin ships a
  client ID shared by every install, with a settings field to override it.
- **Require the user to supply it** when the service issues keys per *developer*
  — TheTVDB's terms mean the plugin cannot ship one, so it is inert until a key
  is saved and its settings panel says exactly that.

Store it with `context["secrets"]`. Tokens minted *from* a key (TheTVDB's bearer
token) belong in `context["cache"]`, which is TTL-bounded and process-local — the
key is the durable credential, the token is not.

## Shadowing

`metadata.shadows` names a built-in source this plugin replaces. While the plugin
is enabled, that source disappears from the registry; disable it and the built-in
returns. Nothing about the user's saved rows changes, and the legacy alias route
for that source transparently serves the plugin instead.

This is how a plugin can supersede an in-tree integration without anyone
migrating a configuration.

## Sources the host provides

| Source | Kind | Notes |
|---|---|---|
| `tmdb` | builtin | Always present, never uninstallable — the metadata backbone. |
| `warp` | builtin | Continue Watching and Based on Watched. Owned by the active *tracker*, so it survives any catalog plugin being installed. |
| `trakt` | legacy | The in-tree Trakt integration. Shadowable. |

## HTTP surface

| Route | Purpose |
|---|---|
| `GET /api/v1/catalog/definitions` | every source and its lists — drives the Settings picker |
| `GET /api/v1/catalog/source/{source_id}/{list_id}` | fetch a window (`media_type`, `limit`, `offset`, `params` as JSON) |
| `GET /api/v1/catalog/tmdb/{category}` | legacy alias, delegates to the same service |
| `GET /api/v1/catalog/trakt/{category}` | legacy alias, follows the shadow |

Installing a plugin changes `/definitions`, and the picker rebuilds from it. That
is the whole mechanism — there is no client-side registration step.

## Testing a plugin

```bash
curl -s -X POST localhost:8000/api/v1/plugins/install -H 'Content-Type: application/json' -d "{\"source\": \"$(pwd)/plugins/my-catalog\"}"
```

```bash
curl -s -X POST localhost:8000/api/v1/plugins/my-catalog/enable
```

```bash
curl -s 'localhost:8000/api/v1/catalog/definitions' | python -m json.tool
```

Then walk a list to its end and check for gaps — the property the pool model
guarantees, and the one worth verifying against a real service:

```bash
python -c "
import requests
seen, off = [], 0
while True:
    r = requests.get('http://localhost:8000/api/v1/catalog/source/my-catalog/genre_horror',
                     params={'media_type':'movie','limit':40 if off==0 else 20,'offset':off}, timeout=90).json()
    ids=[i['id'] for i in r['items']]; seen+=ids; off+=len(ids)
    if not r['has_more'] or not ids: break
print('fetched', len(seen), 'unique', len(set(seen)))
"
```

`fetched == unique` and termination on `has_more: false` is what you are looking
for.

## Related

- Contract source: `warp_mediacenter/backend/plugins/contracts/catalog.py`
- Facade: `warp_mediacenter/backend/plugins/services/catalog_service.py`
- Pooling and pagination: `warp_mediacenter/backend/plugins/services/catalog_cache.py`
- The tracker contract, whose shape this mirrors:
  `warp_mediacenter/backend/plugins/contracts/tracker.py`
