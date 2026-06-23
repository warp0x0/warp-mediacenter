import { useState, useEffect, useCallback, useRef, useMemo, type ElementType } from 'react'
import { useNavigate } from 'react-router-dom'
import { Loader2, ChevronDown, CheckCircle2 } from 'lucide-react'
import { apiGet } from '@/lib/api'
import PosterCard from '@/components/cards/PosterCard'
import { useNavItem, useNavigation } from '@/navigation/NavigationProvider'
import type { CollectionResponse, MediaItem, UserCollection } from '@/lib/types'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type MediaTypeFilter = 'movie' | 'show'
type SortKey = 'added_at' | 'title' | 'rating' | 'vote_count'
type OrderKey = 'asc' | 'desc'
type SortValue = `${SortKey}-${OrderKey}`

interface SortOption {
  value: SortValue
  label: string
  sort: SortKey
  order: OrderKey
}

const SORT_OPTIONS: SortOption[] = [
  { value: 'added_at-desc', label: 'Date Added (newest)', sort: 'added_at', order: 'desc' },
  { value: 'added_at-asc',  label: 'Date Added (oldest)', sort: 'added_at', order: 'asc'  },
  { value: 'title-asc',     label: 'Name (A–Z)',          sort: 'title',    order: 'asc'  },
  { value: 'title-desc',    label: 'Name (Z–A)',          sort: 'title',    order: 'desc' },
  { value: 'rating-desc',   label: 'Highest Rated',       sort: 'rating',   order: 'desc' },
  { value: 'vote_count-desc', label: 'Most Voted',        sort: 'vote_count', order: 'desc' },
]

const PAGE_SIZE = 20

// ---------------------------------------------------------------------------
// UserCollection → MediaItem adapter
// ---------------------------------------------------------------------------

function toMediaItem(item: UserCollection): MediaItem {
  return {
    id: item.tmdb_id,
    title: item.title,
    type: item.type,
    source_tag: 'collection',
    year: item.year,
    overview: item.overview,
    poster: null,
    license: null,
    rating: item.rating,
    genres: item.genres ?? [],
    origin_country: null,
    external_url: null,
    extra: {},
    poster_path: item.poster_path,
    backdrop_path: item.backdrop_path,
    tmdb_id: item.tmdb_id,
    trakt_id: null,
    media: {
      id: item.tmdb_id,
      title: item.title,
      name: item.title,
      year: item.year,
      overview: item.overview,
      poster_path: item.poster_path,
      backdrop_path: item.backdrop_path,
      rating: item.rating,
      genres: (item.genres ?? []).map((g) => ({ name: g })),
    },
  }
}

// ---------------------------------------------------------------------------
// CollectionSubTab
// ---------------------------------------------------------------------------

interface Props {
  collectionType: 'liked' | 'wishlist'
  EmptyIcon: ElementType
  emptyTitle: string
  emptyHint: string
  mediaType: MediaTypeFilter
  setMediaType: (t: MediaTypeFilter) => void
  sortValue: string
  setSortValue: (s: string) => void
}

export default function CollectionSubTab({ collectionType, EmptyIcon, emptyTitle, emptyHint, mediaType, setMediaType, sortValue, setSortValue }: Props) {
  const navigate = useNavigate()
  const { openMenuForItem, focusNavItem } = useNavigation()

  const [items, setItems] = useState<UserCollection[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [isLoading, setIsLoading] = useState(true)
  const [isLoadingMore, setIsLoadingMore] = useState(false)

  const currentSort = SORT_OPTIONS.find((o) => o.value === sortValue) ?? SORT_OPTIONS[0]
  const pendingFocusFirstCard = useRef(false)

  const sortNavId = `${collectionType}:sort`
  const sortNavConfig = useMemo(() => ({
    onEnter: () => { openMenuForItem(sortNavId) },
    getContextMenu: () => SORT_OPTIONS.map((o) => ({
      key: o.value,
      label: o.label,
      icon: o.value === sortValue ? <CheckCircle2 size={16} className="text-accent" /> : undefined,
      onSelect: async () => {
        if (o.value === sortValue) return
        setSortValue(o.value)
        pendingFocusFirstCard.current = true
      },
    })),
  }), [sortNavId, openMenuForItem, sortValue, setSortValue])
  const sortNavRef = useNavItem<HTMLButtonElement>(sortNavId, sortNavConfig)

  // After a sort change re-fetch completes, focus the first PosterCard
  useEffect(() => {
    if (!pendingFocusFirstCard.current || isLoading) return
    pendingFocusFirstCard.current = false
    requestAnimationFrame(() => {
      const firstCard = document.querySelector<HTMLElement>('[data-nav-item][data-nav-kind="card"]')
      const id = firstCard?.getAttribute('data-nav-id')
      if (id) focusNavItem(id)
    })
  }, [isLoading, focusNavItem])

  // Re-fetch from page 1 whenever filters change
  useEffect(() => {
    let cancelled = false
    setIsLoading(true)
    setItems([])
    setPage(1)

    const params: Record<string, string> = {
      type: mediaType,
      sort: currentSort.sort,
      order: currentSort.order,
      page: '1',
      limit: String(PAGE_SIZE),
    }

    apiGet<CollectionResponse>(`/api/v1/collections/${collectionType}`, params)
      .then((data) => {
        if (cancelled) return
        setItems(data.items)
        setTotal(data.count)
      })
      .catch(() => { if (!cancelled) setItems([]) })
      .finally(() => { if (!cancelled) setIsLoading(false) })

    return () => { cancelled = true }
  }, [collectionType, mediaType, sortValue]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleLoadMore = useCallback(async () => {
    if (isLoadingMore) return
    const nextPage = page + 1
    setIsLoadingMore(true)
    try {
      const data = await apiGet<CollectionResponse>(`/api/v1/collections/${collectionType}`, {
        type: mediaType,
        sort: currentSort.sort,
        order: currentSort.order,
        page: String(nextPage),
        limit: String(PAGE_SIZE),
      })
      setItems((prev) => [...prev, ...data.items])
      setTotal(data.count)
      setPage(nextPage)
    } catch {
      // silently ignore load-more failures
    } finally {
      setIsLoadingMore(false)
    }
  }, [collectionType, currentSort, isLoadingMore, mediaType, page])

  const handleNavigate = useCallback(
    (item: MediaItem) => {
      navigate(`/detail/${item.tmdb_id || item.id}`, { state: { item } })
    },
    [navigate],
  )

  const hasMore = items.length < total

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {/* Controls row */}
      <div
        className="flex-shrink-0 flex items-center justify-between gap-4"
        style={{ padding: 'clamp(12px,1.2vh,20px) clamp(24px,2vw,48px) clamp(10px,1vh,16px)' }}
      >
        {/* Left: Movies / Shows selector */}
        <div className="flex items-center gap-2">
          {(['movie', 'show'] as const).map((t) => (
            <button
              key={t}
              data-nav-item
              data-nav-id={`${collectionType}-type:${t}`}
              data-nav-kind="tab"
              data-nav-axis="horizontal"
              data-nav-group={`${collectionType}-type-tabs`}
              onClick={() => setMediaType(t)}
              className="rounded-full font-medium transition-all duration-200 cursor-pointer"
              style={{
                fontSize: 'clamp(13px,0.85vw,15px)',
                padding: 'clamp(6px,0.45vw,10px) clamp(14px,1.1vw,22px)',
                background: mediaType === t ? 'rgba(255,255,255,0.15)' : 'transparent',
                border: mediaType === t ? '1px solid rgba(255,255,255,0.20)' : '1px solid transparent',
                color: mediaType === t ? 'white' : 'rgba(255,255,255,0.50)',
              }}
            >
              {t === 'movie' ? 'Movies' : 'Shows'}
            </button>
          ))}
        </div>

        {/* Right: Sort dropdown */}
        <div className="flex items-center gap-2">
          <span className="text-white/40" style={{ fontSize: 'clamp(12px,0.75vw,14px)' }}>
            Sort:
          </span>
          <button
            ref={sortNavRef}
            data-nav-item
            data-nav-id={sortNavId}
            data-nav-kind="button"
            data-nav-axis="horizontal"
            data-nav-group={`${collectionType}-controls`}
            onClick={() => openMenuForItem(sortNavId)}
            className="flex items-center gap-2 cursor-pointer rounded-lg border border-white/10 bg-white/5 text-white/80 transition-colors hover:border-white/20 hover:bg-white/8"
            style={{
              fontSize: 'clamp(12px,0.8vw,14px)',
              padding: 'clamp(5px,0.4vw,8px) clamp(10px,0.8vw,14px)',
            }}
          >
            <span>{currentSort.label}</span>
            <ChevronDown size={14} className="text-white/50" />
          </button>
        </div>
      </div>

      {/* Divider */}
      <div className="flex-shrink-0 h-px bg-white/8 mx-[clamp(24px,2vw,48px)]" />

      {/* Scrollable content */}
      <div className="flex-1 min-h-0 overflow-y-auto" data-nav-scroll-container>
        {/* Loading */}
        {isLoading && (
          <div
            className="flex items-center justify-center"
            style={{ paddingTop: 'clamp(48px,10vh,96px)' }}
          >
            <Loader2 size={32} className="animate-spin text-accent" />
          </div>
        )}

        {/* Grid */}
        {!isLoading && items.length > 0 && (
          <>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(var(--poster-width), 1fr))',
                gap: 'clamp(16px,1.5vh,28px) var(--card-gap)',
                padding: 'clamp(16px,1.5vh,24px) clamp(24px,2vw,48px)',
              }}
            >
              {items.map((item, idx) => {
                const mediaItem = toMediaItem(item)
                return (
                  <PosterCard
                    key={item.id}
                    item={mediaItem}
                    onSelect={handleNavigate}
                    onNavigate={handleNavigate}
                    itemIndex={idx}
                    navGroup={`${collectionType}:grid`}
                  />
                )
              })}
            </div>

            {/* Load More */}
            {hasMore && (
              <div
                className="flex items-center justify-center"
                style={{ padding: 'clamp(20px,3vh,40px) 0' }}
              >
                <button
                  data-nav-item
                  data-nav-id={`${collectionType}:load-more`}
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
            {!hasMore && (
              <div
                className="flex justify-center"
                style={{ padding: 'clamp(16px,2.5vh,32px) 0' }}
              >
                <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
                  {total} title{total !== 1 ? 's' : ''} total
                </p>
              </div>
            )}
          </>
        )}

        {/* Empty state */}
        {!isLoading && items.length === 0 && (
          <div
            className="flex flex-col items-center justify-center gap-4 text-fg-muted"
            style={{ paddingTop: 'clamp(48px,12vh,100px)' }}
          >
            <EmptyIcon size={52} className="opacity-15" />
            <p style={{ fontSize: 'var(--body-size)' }}>{emptyTitle}</p>
            <p style={{ fontSize: 'var(--subtitle-size)' }}>{emptyHint}</p>
          </div>
        )}
      </div>
    </div>
  )
}
