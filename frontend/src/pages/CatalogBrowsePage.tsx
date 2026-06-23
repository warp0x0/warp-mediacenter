import { useState, useEffect, useCallback } from 'react'
import { useParams, useSearchParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Loader2 } from 'lucide-react'
import { apiGet } from '@/lib/api'
import PosterCard from '@/components/cards/PosterCard'
import type { CatalogResponse, MediaItem } from '@/lib/types'

const PAGE_SIZE = 20

export default function CatalogBrowsePage() {
  const { provider, category } = useParams<{ provider: string; category: string }>()
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()

  const mediaType = (searchParams.get('type') ?? 'movie') as 'movie' | 'show'
  const title = searchParams.get('title') ?? (category ?? '').replace(/_/g, ' ')

  const [items, setItems] = useState<MediaItem[]>([])
  const [offset, setOffset] = useState(0)
  const [hasMore, setHasMore] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchCatalog = useCallback(
    async (off: number): Promise<CatalogResponse | null> => {
      if (!provider || !category) return null
      return apiGet<CatalogResponse>(`/api/v1/catalog/${provider}/${category}`, {
        media_type: mediaType,
        limit: String(PAGE_SIZE),
        offset: String(off),
      })
    },
    [provider, category, mediaType],
  )

  const computeHasMore = (data: CatalogResponse, currentOffset: number) =>
    data.total !== undefined
      ? currentOffset + data.count < data.total
      : data.count >= PAGE_SIZE

  useEffect(() => {
    let cancelled = false

    setIsLoading(true)
    setItems([])
    setOffset(0)
    setHasMore(false)
    setError(null)

    fetchCatalog(0)
      .then((data) => {
        if (cancelled || !data) return
        setItems(data.items)
        setHasMore(computeHasMore(data, 0))
      })
      .catch(() => {
        if (!cancelled) setError('Failed to load catalog. Is the backend running?')
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false)
      })

    return () => { cancelled = true }
  }, [provider, category, mediaType, fetchCatalog])

  const handleLoadMore = async () => {
    const nextOffset = offset + PAGE_SIZE
    setIsLoadingMore(true)
    try {
      const data = await fetchCatalog(nextOffset)
      if (data) {
        setItems((prev) => [...prev, ...data.items])
        setOffset(nextOffset)
        setHasMore(computeHasMore(data, nextOffset))
      }
    } catch {
      // silently ignore load-more failures
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
          data-nav-id="catalog-browse:back"
          data-nav-kind="button"
          data-nav-role="back"
          onClick={() => navigate(-1)}
          data-nav-initial
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

      {/* Loading state */}
      {isLoading && (
        <div className="flex justify-center items-center" style={{ paddingTop: 'clamp(40px,10vh,80px)' }}>
          <Loader2 size={32} className="animate-spin text-accent" />
        </div>
      )}

      {/* Error state */}
      {!isLoading && error && (
        <div
          className="flex justify-center"
          style={{ paddingTop: 'clamp(40px,10vh,80px)', paddingLeft: 'clamp(24px,2vw,48px)' }}
        >
          <p className="text-danger" style={{ fontSize: 'var(--body-size)' }}>
            {error}
          </p>
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
            {items.map((item, idx) => (
              <PosterCard
                key={item.id}
                item={item}
                onSelect={handleNavigate}
                onNavigate={handleNavigate}
                itemIndex={idx}
              />
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
                data-nav-id="catalog-browse:load-more"
                data-nav-kind="button"
                onClick={handleLoadMore}
                disabled={isLoadingMore}
                className="btn-secondary flex items-center justify-center gap-3 cursor-pointer"
                style={{ width: '150px', height: '40px' }}
              >
                {isLoadingMore ? (
                  <>
                    <Loader2 size={16} className="animate-spin" />
                    Loading…
                  </>
                ) : (
                  'Load More'
                )}
              </button>
            </div>
          )}

          {/* End of list */}
          {!hasMore && items.length > 0 && (
            <div
              className="flex justify-center"
              style={{ padding: 'clamp(20px,2.5vh,36px) 0' }}
            >
              <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
                {items.length} title{items.length !== 1 ? 's' : ''} total
              </p>
            </div>
          )}

          {/* Empty state */}
          {items.length === 0 && (
            <div
              className="flex justify-center"
              style={{ paddingTop: 'clamp(40px,10vh,80px)' }}
            >
              <p className="text-fg-muted" style={{ fontSize: 'var(--body-size)' }}>
                No titles available.
              </p>
            </div>
          )}
        </>
      )}
    </div>
  )
}
