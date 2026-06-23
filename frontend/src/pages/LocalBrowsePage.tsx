import { useState, useEffect, useCallback } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Loader2 } from 'lucide-react'
import { apiGet } from '@/lib/api'
import PosterCard from '@/components/cards/PosterCard'
import type { LibraryListResponse, LibrarySearchItem, MediaItem } from '@/lib/types'

const PAGE_SIZE = 20

function toMediaItem(item: LibrarySearchItem): MediaItem {
  return {
    id: String(item.id),
    title: item.title,
    type: (item.type === 'tv' || item.type === 'show') ? 'show' : 'movie',
    source_tag: 'local',
    year: item.year,
    overview: item.overview,
    poster: item.poster_url ? { url: item.poster_url } : null,
    license: null,
    rating: null,
    genres: [],
    origin_country: null,
    external_url: null,
    extra: {},
    poster_path: null,
    backdrop_path: null,
    tmdb_id: item.tmdb_id,
    trakt_id: null,
    media: {
      id: String(item.id),
      title: item.title,
      name: item.title,
      year: item.year,
      overview: item.overview,
      poster_path: null,
      backdrop_path: null,
      rating: null,
      genres: [],
    },
  }
}

export default function LocalBrowsePage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()

  const mediaType = (searchParams.get('type') ?? 'movie') as 'movie' | 'show'
  const sort = searchParams.get('sort') ?? 'added_at'
  const order = searchParams.get('order') ?? 'desc'
  const title = searchParams.get('title') ?? 'Local Library'

  const endpoint = `/api/v1/library/${mediaType === 'show' ? 'shows' : 'movies'}`

  const [items, setItems] = useState<MediaItem[]>([])
  const [offset, setOffset] = useState(0)
  const [hasMore, setHasMore] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchPage = useCallback(
    (off: number) =>
      apiGet<LibraryListResponse>(endpoint, {
        sort,
        order,
        limit: String(PAGE_SIZE),
        offset: String(off),
        local_only: 'true',
      }),
    [endpoint, sort, order],
  )

  useEffect(() => {
    let cancelled = false
    setIsLoading(true)
    setItems([])
    setOffset(0)
    setHasMore(false)
    setError(null)

    fetchPage(0)
      .then((data) => {
        if (cancelled) return
        setItems(data.items.map(toMediaItem))
        setHasMore(data.has_next)
      })
      .catch(() => {
        if (!cancelled) setError('Failed to load library. Is the backend running?')
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false)
      })

    return () => { cancelled = true }
  }, [fetchPage])

  const handleLoadMore = async () => {
    const nextOffset = offset + PAGE_SIZE
    setIsLoadingMore(true)
    try {
      const data = await fetchPage(nextOffset)
      setItems((prev) => [...prev, ...data.items.map(toMediaItem)])
      setOffset(nextOffset)
      setHasMore(data.has_next)
    } catch {
      // silently ignore
    } finally {
      setIsLoadingMore(false)
    }
  }

  const handleNavigate = useCallback(
    (item: MediaItem) => {
      navigate(`/detail/${item.tmdb_id || item.id}`, { state: { item } })
    },
    [navigate],
  )

  return (
    <div
      data-nav-scroll-container
      className="h-full overflow-y-auto bg-bg-primary"
      style={{ paddingTop: 'var(--tabbar-height)' }}
    >
      {/* Header */}
      <div
        className="relative flex items-center justify-center"
        style={{
          padding: 'clamp(16px,1.5vh,28px) clamp(24px,2vw,48px) clamp(12px,1.2vh,20px)',
        }}
      >
        <button
          data-nav-item
          data-nav-id="local-browse:back"
          data-nav-kind="button"
          data-nav-role="back"
          data-nav-axis="horizontal"
          data-nav-group="local-browse:header"
          data-nav-initial
          onClick={() => navigate(-1)}
          className="absolute left-[clamp(24px,2vw,48px)] btn-secondary flex items-center justify-center gap-[clamp(4px,0.31vw,8px)] cursor-pointer"
          style={{ fontSize: 'clamp(13px,0.9vw,16px)', padding: 'clamp(6px,0.5vw,10px) clamp(12px,1vw,20px)', width: '100px', height: '40px' }}
        >
          <ArrowLeft size={16} />
          Back
        </button>

        <div className="text-center">
          <h1
            className="font-extrabold text-fg-white tracking-tight"
            style={{ fontSize: 'var(--page-title-size)' }}
          >
            {title}
          </h1>
          {!isLoading && !error && items.length > 0 && (
            <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
              {items.length} title{items.length !== 1 ? 's' : ''}{hasMore ? '+' : ''}
            </p>
          )}
        </div>
      </div>

      {/* Loading */}
      {isLoading && (
        <div className="flex justify-center items-center" style={{ paddingTop: 'clamp(40px,10vh,80px)' }}>
          <Loader2 size={32} className="animate-spin text-accent" />
        </div>
      )}

      {/* Error */}
      {!isLoading && error && (
        <div className="flex justify-center" style={{ paddingTop: 'clamp(40px,10vh,80px)' }}>
          <p className="text-danger" style={{ fontSize: 'var(--body-size)' }}>{error}</p>
        </div>
      )}

      {/* Grid */}
      {!isLoading && !error && (
        <>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(var(--poster-width), 1fr))',
              gap: 'clamp(16px,1.5vh,28px) var(--card-gap)',
              padding: '0 clamp(24px,2vw,48px)',
            }}
          >
            {items.map((item) => (
              <PosterCard key={item.id} item={item} onSelect={handleNavigate} onNavigate={handleNavigate} />
            ))}
          </div>

          {/* Load More */}
          {hasMore && (
            <div
              className="flex items-center justify-center"
              style={{ padding: 'clamp(24px,3vh,48px) 0' }}
            >
              <button
                data-nav-item
                data-nav-id="local-browse:load-more"
                data-nav-kind="button"
                data-nav-axis="horizontal"
                data-nav-group="local-browse:footer"
                onClick={handleLoadMore}
                disabled={isLoadingMore}
                className="btn-secondary flex items-center justify-center gap-3 cursor-pointer"
                style={{ width: '150px', height: '40px' }}
              >
                {isLoadingMore ? (
                  <><Loader2 size={16} className="animate-spin" />Loading…</>
                ) : (
                  'Load More'
                )}
              </button>
            </div>
          )}

          {/* End of list */}
          {!hasMore && items.length > 0 && (
            <div className="flex justify-center" style={{ padding: 'clamp(20px,2.5vh,36px) 0' }}>
              <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
                {items.length} title{items.length !== 1 ? 's' : ''} total
              </p>
            </div>
          )}

          {/* Empty */}
          {items.length === 0 && (
            <div className="flex justify-center" style={{ paddingTop: 'clamp(40px,10vh,80px)' }}>
              <p className="text-fg-muted" style={{ fontSize: 'var(--body-size)' }}>
                No local titles found.
              </p>
            </div>
          )}
        </>
      )}
    </div>
  )
}
