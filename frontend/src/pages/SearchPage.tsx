import { useState, useRef, useCallback, useEffect } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { ChevronLeft, ChevronRight, Loader2, Clock } from 'lucide-react'
import PosterCard from '@/components/cards/PosterCard'
import { apiGet } from '@/lib/api'
import { useSearchHistory } from '@/hooks/useSearchHistory'
import type { MediaItem, SearchResultItem } from '@/lib/types'

// ── Backend response shapes ───────────────────────────────────────────────────

interface TmdbSearchResponse {
  query: string
  results: SearchResultItem[]
  count: number
}

interface TraktMediaEntry {
  id: string
  title: string
  type: string
  year: number | null
  overview: string | null
  poster: { url: string } | null
  rating: number | null
  genres: string[]
  extra: Record<string, unknown>
}

interface TraktSearchEntry {
  type: string
  score: number | null
  media: TraktMediaEntry
}

interface TraktSearchResponse {
  query: string
  results: TraktSearchEntry[]
  count: number
}

// ── Converters ────────────────────────────────────────────────────────────────

function tmdbResultToMediaItem(item: SearchResultItem): MediaItem {
  return {
    id: String(item.id ?? item.title),
    title: item.title,
    // Backend may return 'tv' or 'show' for TV series
    type: item.type === 'tv' || item.type === 'show' ? 'show' : 'movie',
    source_tag: 'tmdb',
    year: item.year ?? null,
    overview: item.overview ?? null,
    poster: null,
    license: null,
    rating: item.rating ?? null,
    genres: Array.isArray(item.genres)
      ? item.genres.map((g) => (typeof g === 'string' ? g : (g as { name: string }).name))
      : [],
    origin_country: null,
    external_url: null,
    extra: {},
    poster_path: item.poster_path ?? null,
    backdrop_path: item.backdrop_path ?? null,
    tmdb_id: item.tmdb_id ?? String(item.id ?? ''),
    trakt_id: null,
    media: {
      id: String(item.id ?? item.title),
      title: item.title,
      name: item.title,
      year: item.year ?? null,
      overview: item.overview ?? null,
      poster_path: item.poster_path ?? null,
      backdrop_path: item.backdrop_path ?? null,
      rating: item.rating ?? null,
      genres: [],
    },
  }
}

function traktEntryToMediaItem(entry: TraktSearchEntry): MediaItem {
  const { media } = entry
  const extra = (media.extra ?? {}) as Record<string, unknown>
  const ids = (extra.ids ?? {}) as Record<string, unknown>
  const posterPath = (extra.poster_path as string | null | undefined) ?? null
  const backdropPath = (extra.backdrop_path as string | null | undefined) ?? null
  const tmdbId = ids.tmdb ? String(ids.tmdb) : null
  const traktId = ids.trakt ? String(ids.trakt) : null

  return {
    id: media.id,
    title: media.title,
    type: entry.type === 'show' ? 'show' : 'movie',
    source_tag: 'trakt',
    year: media.year,
    overview: media.overview,
    poster: media.poster as { url: string } | null,
    license: null,
    rating: media.rating,
    genres: media.genres,
    origin_country: null,
    external_url: null,
    extra: {},
    poster_path: posterPath,
    backdrop_path: backdropPath,
    tmdb_id: tmdbId,
    trakt_id: traktId,
    media: {
      id: media.id,
      title: media.title,
      name: media.title,
      year: media.year,
      overview: media.overview,
      poster_path: posterPath,
      backdrop_path: backdropPath,
      rating: media.rating,
      genres: [],
    },
  }
}

// ── ResultRow ─────────────────────────────────────────────────────────────────

interface ResultRowProps {
  label: string
  count: number
  items: MediaItem[]
  onNavigate: (item: MediaItem) => void
}

function ResultRow({ label, count, items, onNavigate }: ResultRowProps) {
  const ribbonRef = useRef<HTMLDivElement>(null)

  const scroll = (dir: 'left' | 'right') => {
    const el = ribbonRef.current
    if (!el) return
    el.scrollBy({ left: dir === 'left' ? -400 : 400, behavior: 'smooth' })
  }

  if (!items.length) return null

  return (
    <div style={{ marginBottom: 'clamp(24px,3vh,44px)' }}>
      <div
        className="flex items-center gap-3"
        style={{
          paddingLeft: '10%',
          paddingRight: '10%',
          marginBottom: 'clamp(8px,0.83vw,16px)',
        }}
      >
        <h2 className="font-bold text-fg-white" style={{ fontSize: 'var(--section-title-size)' }}>
          {label}
        </h2>
        <span className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
          {count} result{count !== 1 ? 's' : ''}
        </span>
      </div>

      <div className="relative group">
        <button
          onClick={() => scroll('left')}
          className="absolute top-1/2 -translate-y-1/2 z-20 bg-black/50 backdrop-blur-sm hover:bg-black/70 text-white rounded-full p-[clamp(4px,0.3vw,8px)] opacity-0 group-hover:opacity-100 transition-opacity duration-200 cursor-pointer shadow-[0_2px_8px_rgba(0,0,0,0.4)]"
          style={{ left: 'clamp(4px,0.3vw,8px)' }}
        >
          <ChevronLeft size={50} />
        </button>

        <div
          ref={ribbonRef}
          className="flex gap-[var(--card-gap)] overflow-hidden scrollbar-hidden"
          style={{
            paddingLeft: '10%',
            paddingRight: '10%',
            paddingTop: '4px',
            paddingBottom: '8px',
          }}
        >
          {items.map((item) => (
            <PosterCard
              key={item.id}
              item={item}
              onSelect={onNavigate}
              onNavigate={onNavigate}
            />
          ))}
        </div>

        <button
          onClick={() => scroll('right')}
          className="absolute top-1/2 -translate-y-1/2 z-20 bg-black/50 backdrop-blur-sm hover:bg-black/70 text-white rounded-full p-[clamp(4px,0.3vw,8px)] opacity-0 group-hover:opacity-100 transition-opacity duration-200 cursor-pointer shadow-[0_2px_8px_rgba(0,0,0,0.4)]"
          style={{ right: 'clamp(4px,0.3vw,8px)' }}
        >
          <ChevronRight size={50} />
        </button>
      </div>
    </div>
  )
}

// ── SearchPage ────────────────────────────────────────────────────────────────

export default function SearchPage() {
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const { history, addQuery } = useSearchHistory()

  const [inputValue, setInputValue] = useState('')
  const [activeQuery, setActiveQuery] = useState('')
  const [tmdbMovies, setTmdbMovies] = useState<MediaItem[]>([])
  const [tmdbShows, setTmdbShows] = useState<MediaItem[]>([])
  const [traktItems, setTraktItems] = useState<MediaItem[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const doSearch = useCallback(
    async (q: string, addToHistory = true) => {
      const trimmed = q.trim()
      if (!trimmed) return

      setActiveQuery(trimmed)
      setSearchParams({ q: trimmed }, { replace: true })
      setIsLoading(true)
      setError(null)
      setTmdbMovies([])
      setTmdbShows([])
      setTraktItems([])

      const [tmdbResult, traktResult] = await Promise.allSettled([
        apiGet<TmdbSearchResponse>('/api/v1/search/tmdb', { q: trimmed, type: 'all' }),
        apiGet<TraktSearchResponse>('/api/v1/search/trakt', { q: trimmed, type: 'all', limit: '50' }),
      ])

      setIsLoading(false)

      if (tmdbResult.status === 'fulfilled') {
        const allItems = tmdbResult.value.results.map(tmdbResultToMediaItem)
        setTmdbMovies(allItems.filter((i) => i.type === 'movie'))
        setTmdbShows(allItems.filter((i) => i.type === 'show'))
      }
      if (traktResult.status === 'fulfilled') {
        setTraktItems(traktResult.value.results.map(traktEntryToMediaItem))
      }
      if (tmdbResult.status === 'rejected' && traktResult.status === 'rejected') {
        setError('Search failed. Is the backend running?')
      }

      if (addToHistory) {
        addQuery(trimmed)
      }
    },
    [setSearchParams, addQuery],
  )

  // Restore search from URL on mount (Back button scenario)
  useEffect(() => {
    const q = searchParams.get('q') ?? ''
    if (q) {
      setInputValue(q)
      doSearch(q, false)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') doSearch(inputValue)
  }

  const handleNavigate = useCallback(
    (item: MediaItem) => {
      navigate(`/detail/${item.tmdb_id || item.id}`, { state: { item } })
    },
    [navigate],
  )

  const hasResults = tmdbMovies.length > 0 || tmdbShows.length > 0 || traktItems.length > 0
  const showNoResults = activeQuery && !isLoading && !error && !hasResults

  return (
    <div
      className="h-full overflow-y-auto bg-bg-primary"
      style={{ paddingTop: 'var(--tabbar-height)' }}
    >
      {/* Search bar */}
      <div
        className="flex justify-center"
        style={{ padding: 'clamp(28px,3.5vh,52px) 0 clamp(20px,2.5vh,36px)' }}
      >
        <div className="flex items-center gap-3" style={{ width: '80%' }}>
          <input
            ref={inputRef}
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search movies & shows…"
            className="flex-1 input-field"
            style={{
              fontSize: 'var(--body-size)',
              height: 'clamp(44px,5vh,56px)',
              paddingLeft: '10px',
              paddingRight: '10px',
            }}
            autoFocus
          />
          <button
            onClick={() => doSearch(inputValue)}
            disabled={isLoading || !inputValue.trim()}
            className="btn-primary flex items-center gap-2 flex-shrink-0"
            style={{
              height: 'clamp(44px,5vh,56px)',
              fontSize: 'var(--body-size)',
              paddingLeft: 'clamp(16px,1.5vw,28px)',
              paddingRight: 'clamp(16px,1.5vw,28px)',
            }}
          >
            {isLoading ? <Loader2 size={18} className="animate-spin" /> : null}
            Search
          </button>
        </div>
      </div>

      {/* Loading */}
      {isLoading && (
        <div
          className="flex justify-center items-center"
          style={{ paddingTop: 'clamp(40px,10vh,80px)' }}
        >
          <Loader2 size={36} className="animate-spin text-accent" />
        </div>
      )}

      {/* Error */}
      {!isLoading && error && (
        <div className="flex justify-center" style={{ paddingTop: 'clamp(40px,10vh,80px)' }}>
          <p className="text-danger" style={{ fontSize: 'var(--body-size)' }}>
            {error}
          </p>
        </div>
      )}

      {/* No results */}
      {showNoResults && (
        <div
          className="flex flex-col items-center gap-3"
          style={{ paddingTop: 'clamp(40px,10vh,80px)' }}
        >
          <p className="text-fg-muted" style={{ fontSize: 'var(--body-size)' }}>
            No results found for "{activeQuery}"
          </p>
        </div>
      )}

      {/* Results */}
      {!isLoading && !error && hasResults && (
        <div style={{ marginTop: 'clamp(4px,0.5vh,8px)' }}>
          <ResultRow
            label="Movies (TMDb)"
            count={tmdbMovies.length}
            items={tmdbMovies}
            onNavigate={handleNavigate}
          />
          <ResultRow
            label="Shows (TMDb)"
            count={tmdbShows.length}
            items={tmdbShows}
            onNavigate={handleNavigate}
          />
          <ResultRow
            label="Trakt"
            count={traktItems.length}
            items={traktItems}
            onNavigate={handleNavigate}
          />
        </div>
      )}

      {/* Idle state: search history + prompt */}
      {!activeQuery && !isLoading && (
        <div
          className="flex flex-col items-center"
          style={{ paddingTop: 'clamp(24px,3vh,44px)' }}
        >
          {history.length > 0 ? (
            <div style={{ width: '80%' }}>
              <p
                className="text-fg-muted uppercase tracking-widest"
                style={{
                  fontSize: 'clamp(11px,0.7vw,13px)',
                  marginBottom: 'clamp(8px,1vh,14px)',
                }}
              >
                Recent Searches
              </p>
              {history.map((q) => (
                <button
                  key={q}
                  onClick={() => {
                    setInputValue(q)
                    doSearch(q)
                  }}
                  className="flex items-center gap-3 w-full text-left rounded hover:bg-white/5 transition-colors cursor-pointer"
                  style={{
                    padding: 'clamp(8px,0.8vh,13px) clamp(8px,0.6vw,12px)',
                    fontSize: 'var(--body-size)',
                  }}
                >
                  <Clock size={14} className="text-fg-muted flex-shrink-0" />
                  <span className="text-fg-white truncate">{q}</span>
                </button>
              ))}
            </div>
          ) : (
            <p className="text-fg-muted" style={{ fontSize: 'var(--body-size)' }}>
              Search across TMDb &amp; Trakt
            </p>
          )}
        </div>
      )}
    </div>
  )
}
