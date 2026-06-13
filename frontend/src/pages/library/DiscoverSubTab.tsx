import { useState, useCallback, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useCatalog } from '@/hooks/useCatalog'
import { useApi } from '@/hooks/useApi'
import PosterCard from '@/components/cards/PosterCard'
import type { CatalogResponse, MediaItem } from '@/lib/types'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface TraktListResponse {
  items: MediaItem[]
  count: number
}

// ---------------------------------------------------------------------------
// DiscoverRow — one horizontal ribbon section
// ---------------------------------------------------------------------------

interface DiscoverRowProps {
  title: string
  items: MediaItem[]
  isLoading: boolean
  isError?: boolean
  seeMorePath?: string
  onNavigate: (item: MediaItem) => void
}

function DiscoverRow({ title, items, isLoading, isError, seeMorePath, onNavigate }: DiscoverRowProps) {
  const navigate = useNavigate()
  const scrollRef = useRef<HTMLDivElement>(null)

  const scroll = (dir: 'left' | 'right') => {
    scrollRef.current?.scrollBy({ left: dir === 'left' ? -700 : 700, behavior: 'smooth' })
  }

  // Silently hide rows that errored (e.g. Trakt not authenticated)
  if (isError && !isLoading) return null

  return (
    <div style={{ marginBottom: 'clamp(20px,2vh,32px)' }}>
      {/* Section header */}
      <div
        className="flex items-center justify-between"
        style={{
          padding: '0 clamp(20px,2vw,40px)',
          marginBottom: 'clamp(6px,0.5vh,10px)',
        }}
      >
        <h3
          className="font-bold text-white"
          style={{ fontSize: 'clamp(14px,0.95vw,17px)', letterSpacing: '0.02em' }}
        >
          {title}
        </h3>
        {seeMorePath && !isLoading && items.length > 0 && (
          <button
            onClick={() => navigate(seeMorePath)}
            className="flex items-center gap-1 font-medium transition-colors cursor-pointer"
            style={{ fontSize: 'clamp(11px,0.75vw,13px)', color: 'var(--accent)' }}
          >
            See More <ChevronRight size={13} />
          </button>
        )}
      </div>

      {/* Skeleton placeholders */}
      {isLoading && (
        <div
          className="flex overflow-hidden"
          style={{ gap: 'var(--card-gap)', padding: '0 clamp(20px,2vw,40px)' }}
        >
          {Array.from({ length: 8 }).map((_, i) => (
            <div
              key={i}
              className="flex-shrink-0 animate-pulse"
              style={{ width: 'var(--poster-width)' }}
            >
              <div
                className="bg-white/5 rounded-[var(--card-radius)]"
                style={{ height: 'var(--poster-height)' }}
              />
            </div>
          ))}
        </div>
      )}

      {/* Ribbon with left/right chevrons */}
      {!isLoading && items.length > 0 && (
        <div className="relative group">
          {/* Left chevron */}
          <button
            onClick={() => scroll('left')}
            className="absolute top-1/2 -translate-y-1/2 z-20 bg-black/60 backdrop-blur-sm hover:bg-black/80 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-200 cursor-pointer shadow-[0_2px_8px_rgba(0,0,0,0.5)]"
            style={{ left: 'clamp(4px,0.4vw,10px)', padding: 'clamp(5px,0.35vw,8px)' }}
          >
            <ChevronLeft size={50} />
          </button>

          {/* Right chevron */}
          <button
            onClick={() => scroll('right')}
            className="absolute top-1/2 -translate-y-1/2 z-20 bg-black/60 backdrop-blur-sm hover:bg-black/80 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-200 cursor-pointer shadow-[0_2px_8px_rgba(0,0,0,0.5)]"
            style={{ right: 'clamp(4px,0.4vw,10px)', padding: 'clamp(5px,0.35vw,8px)' }}
          >
            <ChevronRight size={50} />
          </button>

          {/* Scrollable items */}
          <div
            ref={scrollRef}
            className="flex overflow-hidden scrollbar-hidden"
            style={{
              gap: 'var(--card-gap)',
              padding: '4px clamp(20px,2vw,40px) 6px',
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
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// DiscoverSubTab
// ---------------------------------------------------------------------------

export default function DiscoverSubTab() {
  const navigate = useNavigate()
  const [mediaType, setMediaType] = useState<'movie' | 'show'>('movie')

  // 7 standard Trakt catalog sections
  const trending    = useCatalog('trakt', 'trending',    mediaType, undefined, 20)
  const popular     = useCatalog('trakt', 'popular',     mediaType, undefined, 20)
  const anticipated = useCatalog('trakt', 'anticipated', mediaType, undefined, 20)
  const watched     = useCatalog('trakt', 'watched',     mediaType, undefined, 20)
  const played      = useCatalog('trakt', 'played',      mediaType, undefined, 20)
  const collected   = useCatalog('trakt', 'collected',   mediaType, undefined, 20)
  const favorited   = useCatalog('trakt', 'favorited',   mediaType, undefined, 20)

  // 2 Trakt-auth-gated sections (hidden on 401/503)
  const recommendations = useApi<TraktListResponse>(
    '/api/v1/trakt/recommendations',
    { media_type: mediaType },
    { errorRetryCount: 0 },
  )
  const watchlistResult = useApi<TraktListResponse>(
    '/api/v1/trakt/watchlist',
    { media_type: mediaType },
    { errorRetryCount: 0 },
  )

  const handleNavigate = useCallback(
    (item: MediaItem) => {
      navigate(`/detail/${item.tmdb_id || item.id}`, { state: { item } })
    },
    [navigate],
  )

  const catalogSections: Array<{
    key: string
    label: string
    result: ReturnType<typeof useCatalog>
  }> = [
    { key: 'trending',    label: 'Trending Now',     result: trending    },
    { key: 'popular',     label: 'Popular',           result: popular     },
    { key: 'anticipated', label: 'Most Anticipated',  result: anticipated },
    { key: 'watched',     label: 'Most Watched',      result: watched     },
    { key: 'played',      label: 'Most Played',       result: played      },
    { key: 'collected',   label: 'Most Collected',    result: collected   },
    { key: 'favorited',   label: 'Most Favorited',    result: favorited   },
  ]

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {/* Movies / Shows toggle */}
      <div
        className="flex-shrink-0 flex justify-center"
        style={{ padding: 'clamp(12px,1.2vh,20px) 0 clamp(10px,1vh,16px)' }}
      >
        <div className="flex items-center gap-2">
          {(['movie', 'show'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setMediaType(t)}
              className="rounded-full font-medium transition-all duration-200 cursor-pointer"
              style={{
                fontSize: 'clamp(13px,0.85vw,15px)',
                padding: 'clamp(6px,0.45vw,10px) clamp(16px,1.3vw,26px)',
                background: mediaType === t ? 'rgba(255,255,255,0.15)' : 'transparent',
                border: mediaType === t
                  ? '1px solid rgba(255,255,255,0.20)'
                  : '1px solid transparent',
                color: mediaType === t ? 'white' : 'rgba(255,255,255,0.50)',
              }}
            >
              {t === 'movie' ? 'Movies' : 'Shows'}
            </button>
          ))}
        </div>
      </div>

      {/* Divider */}
      <div className="flex-shrink-0 h-px bg-white/8 mx-[clamp(20px,2vw,40px)]" />

      {/* Scrollable ribbon sections */}
      <div
        className="flex-1 min-h-0 overflow-y-auto"
        style={{ paddingTop: 'clamp(16px,1.5vh,24px)' }}
      >
        {catalogSections.map((section) => (
          <DiscoverRow
            key={`${section.key}-${mediaType}`}
            title={section.label}
            items={(section.result.data as CatalogResponse | undefined)?.items ?? []}
            isLoading={section.result.isLoading}
            seeMorePath={`/catalog/trakt/${section.key}?type=${mediaType}&title=${encodeURIComponent(section.label)}`}
            onNavigate={handleNavigate}
          />
        ))}

        <DiscoverRow
          key={`recommendations-${mediaType}`}
          title="Recommended For You"
          items={recommendations.data?.items ?? []}
          isLoading={recommendations.isLoading}
          isError={!!recommendations.error}
          onNavigate={handleNavigate}
        />

        <DiscoverRow
          key={`watchlist-${mediaType}`}
          title="Your Watchlist"
          items={watchlistResult.data?.items ?? []}
          isLoading={watchlistResult.isLoading}
          isError={!!watchlistResult.error}
          onNavigate={handleNavigate}
        />

        {/* Bottom spacer */}
        <div style={{ height: 'clamp(20px,2vh,32px)' }} />
      </div>
    </div>
  )
}
