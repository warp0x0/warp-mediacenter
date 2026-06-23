import { useRef, useEffect, useState, useCallback } from 'react'
import { mutate } from 'swr'
import type { MediaItem, CollectionItemPayload } from '@/lib/types'
import PosterCard from './PosterCard'
import ContextMenu from '@/components/shared/ContextMenu'
import { markAsWatched } from '@/hooks/useLibrary'
import { useIsLiked, useIsWishlisted } from '@/hooks/useCollections'
import { CheckCircle2, Heart, Plus } from 'lucide-react'

interface CatalogRowProps {
  title: string
  items: MediaItem[]
  isLoading?: boolean
  onCardSelect: (item: MediaItem) => void
  onCardNavigate: (item: MediaItem) => void
}

function buildCollectionPayload(item: MediaItem): CollectionItemPayload {
  return {
    tmdb_id: item.tmdb_id ? String(item.tmdb_id) : '',
    type: item.type === 'show' ? 'show' : 'movie',
    title: item.title || item.media?.title || item.media?.name || 'Unknown',
    year: item.year ?? null,
    poster_path: item.poster_path ?? item.media?.poster_path ?? null,
    backdrop_path: item.backdrop_path ?? item.media?.backdrop_path ?? null,
    rating: item.rating ?? null,
    overview: item.overview ?? item.media?.overview ?? null,
  }
}

function numberFromExtra(value: unknown): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  if (typeof value === 'string' && value.trim()) {
    const parsed = Number(value)
    if (Number.isFinite(parsed)) return parsed
  }
  return undefined
}

function refreshWatchedCatalogs() {
  void mutate((key) => {
    if (!Array.isArray(key)) return false
    const path = key[0]
    return path === '/api/v1/catalog/trakt/continue_watching'
      || path === '/api/v1/catalog/continue-watching'
      || path === '/api/v1/catalog/trakt/based_on_watched'
  })
}

export default function CatalogRow({
  title,
  items,
  isLoading,
  onCardSelect,
  onCardNavigate,
}: CatalogRowProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const navGroup = `catalog-row:${title.replace(/[^a-zA-Z0-9:_-]+/g, '-')}`
  const [contextMenu, setContextMenu] = useState<{ open: boolean; item: MediaItem | null; loading: boolean }>({
    open: false, item: null, loading: false,
  })
  const contextAnchorRef = useRef<HTMLElement | null>(null)

  const contextTmdbId = contextMenu.item?.tmdb_id ? String(contextMenu.item.tmdb_id) : null
  const { isLiked, toggle: toggleLike } = useIsLiked(contextTmdbId)
  const { isWishlisted, toggle: toggleWishlist } = useIsWishlisted(contextTmdbId)

  // Event delegation for remotelongpress on PosterCard items
  useEffect(() => {
    const el = containerRef.current
    if (!el) return
    const handler = (e: Event) => {
      const target = e.target as HTMLElement
      const idxAttr = target.closest('[data-item-index]')?.getAttribute('data-item-index')
      if (idxAttr != null) {
        const idx = parseInt(idxAttr, 10)
        if (!isNaN(idx) && items[idx]) {
          contextAnchorRef.current = target.closest('[data-item-index]') as HTMLElement
          setContextMenu({ open: true, item: items[idx], loading: false })
        }
      }
    }
    el.addEventListener('remotelongpress', handler)
    return () => el.removeEventListener('remotelongpress', handler)
  }, [items])

  // Restore focus to the card that opened the context menu after it closes
  const prevContextMenuOpen = useRef(contextMenu.open)
  useEffect(() => {
    if (prevContextMenuOpen.current && !contextMenu.open && contextAnchorRef.current) {
      const anchor = contextAnchorRef.current
      requestAnimationFrame(() => {
        anchor.focus({ preventScroll: true })
      })
      contextAnchorRef.current = null
    }
    prevContextMenuOpen.current = contextMenu.open
  }, [contextMenu.open])

  const handleContextMenuAction = useCallback(async (key: string) => {
    const item = contextMenu.item
    if (!item) return
    if (key === 'mark-watched') {
      setContextMenu((prev) => ({ ...prev, loading: true }))
      try {
        await markAsWatched({
          tmdb_id: item.tmdb_id || '',
          media_type: item.type === 'show' ? 'show' : 'movie',
          playback_id: item.type === 'show'
            ? numberFromExtra(item.extra?.resume_playback_id)
            : numberFromExtra(item.extra?.playback_id),
          title: item.title || item.media?.title || item.media?.name || 'Unknown',
          year: item.year ?? null,
          overview: item.overview ?? item.media?.overview ?? null,
          poster_path: item.poster_path ?? item.media?.poster_path ?? null,
          backdrop_path: item.backdrop_path ?? item.media?.backdrop_path ?? null,
        })
        refreshWatchedCatalogs()
      } catch {
        // silently fail
      }
      setContextMenu({ open: false, item: null, loading: false })
    } else if (key === 'toggle-like') {
      const payload = buildCollectionPayload(item)
      await toggleLike(payload)
      setContextMenu({ open: false, item: null, loading: false })
    } else if (key === 'toggle-wishlist') {
      const payload = buildCollectionPayload(item)
      await toggleWishlist(payload)
      setContextMenu({ open: false, item: null, loading: false })
    }
  }, [contextMenu.item, toggleLike, toggleWishlist])
  if (isLoading) {
    return (
      <div className="mb-[clamp(12px,1.25vw,24px)]">
        <div className="flex items-center justify-between px-[clamp(8px,0.83vw,16px)] mb-[clamp(6px,0.52vw,12px)]">
          <h2
            className="font-bold text-fg-white"
            style={{ fontSize: 'var(--section-title-size)' }}
          >
            {title}
          </h2>
        </div>
        <div className="flex gap-[var(--card-gap)] px-[clamp(8px,0.83vw,16px)] overflow-hidden">
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
      </div>
    )
  }

  if (!items.length) {
    return (
      <div className="mb-[clamp(12px,1.25vw,24px)]">
        <h2
          className="font-bold text-fg-white px-[clamp(8px,0.83vw,16px)] mb-[clamp(6px,0.52vw,12px)]"
          style={{ fontSize: 'var(--section-title-size)' }}
        >
          {title}
        </h2>
        <p className="text-fg-muted text-body px-[clamp(8px,0.83vw,16px)]">No items available</p>
      </div>
    )
  }

  return (
    <div className="mb-[clamp(12px,1.25vw,24px)]">
      <div className="flex items-center justify-between px-[clamp(8px,0.83vw,16px)] mb-[clamp(6px,0.52vw,12px)]">
        <h2
          className="font-bold text-fg-white"
          style={{ fontSize: 'var(--section-title-size)' }}
        >
          {title}
        </h2>
        <button
          data-nav-item
          data-nav-id={`${navGroup}:see-all`}
          data-nav-kind="button"
          className="text-subtitle text-accent hover:text-accent-hover font-medium transition-colors cursor-pointer"
        >
          See All
        </button>
      </div>

      <div ref={containerRef} className="flex gap-[var(--card-gap)] px-[clamp(8px,0.83vw,16px)] overflow-x-auto scrollbar-hidden pb-[clamp(4px,0.31vw,8px)]">
        {items.map((item, idx) => (
          <PosterCard
            key={item.id}
            item={item}
            onSelect={onCardSelect}
            onNavigate={onCardNavigate}
            itemIndex={idx}
            navGroup={navGroup}
          />
        ))}
      </div>

      <ContextMenu
        open={contextMenu.open}
        items={[
          {
            key: 'toggle-like',
            label: isLiked ? 'Unlike' : 'Like',
            icon: <Heart size={16} fill={isLiked ? 'currentColor' : 'none'} className={isLiked ? 'text-red-400' : ''} />,
          },
          {
            key: 'toggle-wishlist',
            label: isWishlisted ? 'Remove from Wishlist' : 'Add to Wishlist',
            icon: isWishlisted
              ? <CheckCircle2 size={16} className="text-emerald-400" />
              : <Plus size={16} />,
          },
          { key: 'mark-watched', label: 'Mark as Watched', icon: <CheckCircle2 size={16} /> },
        ]}
        onSelect={handleContextMenuAction}
        onClose={() => setContextMenu({ open: false, item: null, loading: false })}
        loading={contextMenu.loading}
        anchorRef={contextAnchorRef}
      />
    </div>
  )
}
