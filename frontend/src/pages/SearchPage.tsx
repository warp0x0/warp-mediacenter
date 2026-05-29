import { useMemo } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Search } from 'lucide-react'
import CatalogRow from '@/components/cards/CatalogRow'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { useApi } from '@/hooks/useApi'
import type { MediaItem, SearchResponse, SearchResultItem } from '@/lib/types'

const SOURCE_COLORS: Record<string, string> = {
  local: 'bg-success/20 text-success border-success/30',
  tmdb: 'bg-accent/20 text-accent border-accent/30',
  trakt: 'bg-danger/20 text-danger border-danger/30',
}

const SOURCE_LABELS: Record<string, string> = {
  local: 'Local',
  tmdb: 'TMDb',
  trakt: 'Trakt',
}

function toMediaItem(item: SearchResultItem): MediaItem {
  return {
    id: String(item.id ?? item.title),
    title: item.title,
    type: item.type === 'tv' ? 'show' : 'movie',
    source_tag: item.source,
    year: item.year ?? null,
    overview: item.overview ?? null,
    poster: null,
    license: null,
    rating: item.rating ?? null,
    genres: Array.isArray(item.genres)
      ? item.genres.map((g) => (typeof g === 'string' ? g : g.name))
      : [],
    origin_country: null,
    external_url: null,
    extra: {},
    poster_path: item.poster_path ?? null,
    backdrop_path: item.backdrop_path ?? null,
    tmdb_id: item.tmdb_id ?? null,
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

export default function SearchPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const query = searchParams.get('q') || ''

  const { data, isLoading, error } = useApi<SearchResponse>(
    query ? '/api/v1/search/unified' : null,
    query ? { q: query, limit: '50' } : undefined,
  )

  const groups = useMemo(() => {
    if (!data) return []
    const map = new Map<string, SearchResultItem[]>()
    for (const item of data.results) {
      const src = item.source || 'unknown'
      if (!map.has(src)) map.set(src, [])
      map.get(src)!.push(item)
    }
    return ['local', 'tmdb', 'trakt']
      .filter((s) => map.has(s))
      .map((source) => ({
        source,
        label: SOURCE_LABELS[source] ?? source,
        items: map.get(source)!.map(toMediaItem),
        count: map.get(source)!.length,
      }))
  }, [data])

  if (isLoading) return <LoadingSpinner />

  return (
    <div className="relative h-full overflow-y-auto">
      <div className="flex items-center justify-between px-[clamp(8px,0.83vw,16px)] pt-[clamp(8px,0.83vw,16px)] pb-[clamp(4px,0.31vw,8px)]">
        <div className="flex items-center gap-[clamp(8px,0.63vw,14px)]">
          <button
            onClick={() => navigate(-1)}
            className="btn-secondary flex items-center gap-[clamp(4px,0.31vw,8px)] cursor-pointer"
          >
            <ArrowLeft size={16} /> Back
          </button>
          <h1
            className="font-extrabold text-fg-white tracking-tight"
            style={{ fontSize: 'var(--page-title-size)' }}
          >
            Results for: "{query}"
            {data ? ` (${data.count})` : ''}
          </h1>
        </div>
      </div>

      {error && (
        <div className="px-[clamp(8px,0.83vw,16px)]">
          <p className="text-danger" style={{ fontSize: 'var(--body-size)' }}>
            Search failed. Is the backend running?
          </p>
        </div>
      )}

      {!error && !groups.length && (
        <div className="flex flex-col items-center justify-center py-[clamp(40px,8vh,80px)] text-fg-muted">
          <Search size={40} className="mb-[clamp(12px,1.25vw,24px)] opacity-30" />
          <p style={{ fontSize: 'var(--body-size)' }}>No results for "{query}"</p>
        </div>
      )}

      {groups.map((group) => (
        <div key={group.source} className="mb-[clamp(12px,1.25vw,24px)]">
          <div className="flex items-center gap-[clamp(6px,0.52vw,12px)] px-[clamp(8px,0.83vw,16px)] mb-[clamp(6px,0.52vw,12px)]">
            <span
              className={`inline-flex items-center rounded-pill px-[clamp(8px,0.63vw,14px)] py-[clamp(2px,0.16vw,4px)] border text-subtitle font-semibold ${SOURCE_COLORS[group.source] ?? 'bg-white/10 text-fg-muted border-white/10'}`}
            >
              {group.label} ({group.count})
            </span>
          </div>

          <CatalogRow
            title={group.label}
            items={group.items}
            onCardSelect={() => {}}
            onCardNavigate={(item) => {
              const navId = item.tmdb_id || item.id
              if (item.type === 'show') {
                navigate(`/shows/${navId}`, { state: { item } })
              } else {
                navigate(`/detail/${navId}`, { state: { item } })
              }
            }}
          />
        </div>
      ))}
    </div>
  )
}
