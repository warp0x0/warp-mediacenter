import { useState, useCallback, useRef } from 'react'
import { mutate as swrGlobalMutate } from 'swr'
import { useNavigate } from 'react-router-dom'
import { FolderSearch, ScanLine, ChevronLeft, ChevronRight } from 'lucide-react'
import { useLibraryList } from '@/hooks/useLibrary'
import PosterCard from '@/components/cards/PosterCard'
import ScanDialog from '@/components/media/ScanDialog'
import type { LibrarySearchItem, MediaItem } from '@/lib/types'

// ---------------------------------------------------------------------------
// Adapter
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// LocalRibbon — a labelled horizontal scroll of posters
// ---------------------------------------------------------------------------

interface LocalRibbonProps {
  title: string
  items: MediaItem[]
  isLoading: boolean
  onNavigate: (item: MediaItem) => void
  seeMorePath?: string
}

function LocalRibbon({ title, items, isLoading, onNavigate, seeMorePath }: LocalRibbonProps) {
  const navigate = useNavigate()
  const scrollRef = useRef<HTMLDivElement>(null)

  const scroll = (dir: 'left' | 'right') => {
    scrollRef.current?.scrollBy({ left: dir === 'left' ? -700 : 700, behavior: 'smooth' })
  }

  if (!isLoading && items.length === 0) return null

  return (
    <div style={{ marginBottom: 'clamp(20px,2vh,32px)' }}>
      <div
        className="flex items-center justify-between"
        style={{ padding: '0 clamp(20px,2vw,36px)', marginBottom: 'clamp(6px,0.5vh,10px)' }}
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
            className="flex items-center gap-1 font-medium transition-colors cursor-pointer hover:text-white"
            style={{ fontSize: 'clamp(11px,0.75vw,13px)', color: 'var(--accent)' }}
          >
            See More <ChevronRight size={13} />
          </button>
        )}
      </div>

      {/* Skeleton */}
      {isLoading && (
        <div
          className="flex overflow-hidden"
          style={{ gap: 'var(--card-gap)', padding: '0 clamp(20px,2vw,36px)' }}
        >
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="flex-shrink-0 animate-pulse" style={{ width: 'var(--poster-width)' }}>
              <div className="bg-white/5 rounded-[var(--card-radius)]" style={{ height: 'var(--poster-height)' }} />
            </div>
          ))}
        </div>
      )}

      {/* Items with chevron controls */}
      {!isLoading && (
        <div className="relative group">
          <button
            onClick={() => scroll('left')}
            className="absolute top-1/2 -translate-y-1/2 z-20 bg-black/60 backdrop-blur-sm hover:bg-black/80 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-200 cursor-pointer shadow-[0_2px_8px_rgba(0,0,0,0.5)]"
            style={{ left: 'clamp(4px,0.4vw,10px)', padding: 'clamp(5px,0.35vw,8px)' }}
          >
            <ChevronLeft size={50} />
          </button>
          <button
            onClick={() => scroll('right')}
            className="absolute top-1/2 -translate-y-1/2 z-20 bg-black/60 backdrop-blur-sm hover:bg-black/80 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-200 cursor-pointer shadow-[0_2px_8px_rgba(0,0,0,0.5)]"
            style={{ right: 'clamp(4px,0.4vw,10px)', padding: 'clamp(5px,0.35vw,8px)' }}
          >
            <ChevronRight size={50} />
          </button>

          <div
            ref={scrollRef}
            className="flex overflow-hidden scrollbar-hidden"
            style={{ gap: 'var(--card-gap)', padding: '4px clamp(20px,2vw,36px) 6px' }}
          >
            {items.map((item) => (
              <PosterCard key={item.id} item={item} onSelect={onNavigate} onNavigate={onNavigate} />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// LocalSubTab
// ---------------------------------------------------------------------------

interface Props {
  mediaType: 'movie' | 'show'
  setMediaType: (t: 'movie' | 'show') => void
}

export default function LocalSubTab({ mediaType, setMediaType }: Props) {
  const navigate = useNavigate()
  const [scanOpen, setScanOpen] = useState(false)
  const listType = mediaType === 'movie' ? 'movies' : 'shows'

  const recentQuery  = useLibraryList(listType, { sort: 'added_at', order: 'desc', limit: 30, localOnly: true })
  const azQuery      = useLibraryList(listType, { sort: 'title',    order: 'asc',  limit: 30, localOnly: true })

  const handleNavigate = useCallback(
    (item: MediaItem) => {
      navigate(`/detail/${item.tmdb_id || item.id}`, { state: { item } })
    },
    [navigate],
  )

  const handleAddToLibrary = useCallback(() => {
    setScanOpen(false)
    // Invalidate all library-related SWR cache entries so the ribbons re-fetch immediately
    swrGlobalMutate(
      (key: unknown) =>
        Array.isArray(key) && typeof key[0] === 'string' && key[0].startsWith('/api/v1/library'),
    )
  }, [])

  const recentItems = (recentQuery.data?.items ?? []).map(toMediaItem)
  const azItems     = (azQuery.data?.items ?? []).map(toMediaItem)
  const hasContent  = recentItems.length > 0 || azItems.length > 0
  const isLoading   = recentQuery.isLoading || azQuery.isLoading

  return (
    <div className="flex h-full overflow-hidden">
      {/* ── Sidebar ── */}
      <div
        className="flex-shrink-0 flex flex-col items-center justify-center gap-5 border-r border-white/5 text-center"
        style={{ width: 'clamp(200px,16vw,280px)', padding: 'clamp(24px,2vw,40px)' }}
      >
        <FolderSearch size={40} className="text-white/15" />
        <div>
          <p className="text-white font-semibold" style={{ fontSize: 'clamp(14px,0.9vw,16px)', marginBottom: 6 }}>
            Add your Collections<br />from Local Drive
          </p>
          <p className="text-white/35" style={{ fontSize: 'clamp(11px,0.72vw,13px)', lineHeight: 1.5 }}>
            Scan folders to import movies and shows into your local library.
          </p>
        </div>
        <button
          onClick={() => setScanOpen(true)}
          className="flex items-center justify-center gap-2 rounded-lg font-semibold transition-all cursor-pointer hover:brightness-110 hover:-translate-y-0.5"
          style={{
            padding: '10px 20px',
            background: 'var(--accent)',
            color: '#000',
            fontSize: 'clamp(13px,0.85vw,15px)',
            width: '100%',
          }}
        >
          <ScanLine size={15} />
          Start Scanning
        </button>
      </div>

      {/* ── Main content ── */}
      <div className="flex flex-col flex-1 min-w-0 h-full overflow-hidden">
        {/* Media type toggle */}
        <div
          className="flex-shrink-0 flex items-center gap-2"
          style={{ padding: 'clamp(12px,1.2vh,20px) clamp(20px,2vw,36px) clamp(10px,1vh,16px)' }}
        >
          {(['movie', 'show'] as const).map((t) => (
            <button
              key={t}
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

        <div className="flex-shrink-0 h-px bg-white/8 mx-[clamp(20px,2vw,36px)]" />

        {/* Ribbons */}
        <div
          className="flex-1 min-h-0 overflow-y-auto"
          style={{ paddingTop: 'clamp(16px,1.5vh,24px)' }}
        >
          <LocalRibbon
            title="Recently Added"
            items={recentItems}
            isLoading={recentQuery.isLoading}
            onNavigate={handleNavigate}
            seeMorePath={`/local/browse?type=${mediaType}&sort=added_at&order=desc&title=Recently+Added`}
          />
          <LocalRibbon
            title="Names A–Z"
            items={azItems}
            isLoading={azQuery.isLoading}
            onNavigate={handleNavigate}
            seeMorePath={`/local/browse?type=${mediaType}&sort=title&order=asc&title=Names+A%E2%80%93Z`}
          />

          {/* Empty state */}
          {!isLoading && !hasContent && (
            <div
              className="flex flex-col items-center justify-center gap-4 text-fg-muted"
              style={{ paddingTop: 'clamp(48px,12vh,100px)' }}
            >
              <FolderSearch size={48} className="opacity-15" />
              <p style={{ fontSize: 'var(--body-size)' }}>No local media yet.</p>
              <p style={{ fontSize: 'var(--subtitle-size)' }}>
                Click "Start Scanning" to import movies and shows.
              </p>
            </div>
          )}

          <div style={{ height: 'clamp(20px,2vh,32px)' }} />
        </div>
      </div>

      <ScanDialog
        open={scanOpen}
        onClose={() => setScanOpen(false)}
        onAddToLibrary={handleAddToLibrary}
      />
    </div>
  )
}
