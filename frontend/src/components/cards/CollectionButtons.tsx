import { Heart, Plus, CheckCircle2 } from 'lucide-react'
import { useIsLiked, useIsWishlisted } from '@/hooks/useCollections'
import type { MediaItem, CollectionItemPayload } from '@/lib/types'

interface CollectionButtonsProps {
  item: MediaItem
  iconSize?: number
}

function buildPayload(item: MediaItem, tmdbId: string): CollectionItemPayload {
  return {
    tmdb_id: tmdbId,
    type: item.type === 'show' ? 'show' : 'movie',
    title: item.title || item.media?.title || item.media?.name || 'Unknown',
    year: item.year ?? null,
    poster_path: item.poster_path ?? item.media?.poster_path ?? null,
    backdrop_path: item.backdrop_path ?? item.media?.backdrop_path ?? null,
    rating: item.rating ?? null,
    overview: item.overview ?? item.media?.overview ?? null,
  }
}

export default function CollectionButtons({ item, iconSize = 14 }: CollectionButtonsProps) {
  const tmdbId = item.tmdb_id ? String(item.tmdb_id) : null
  const { isLiked, toggle: toggleLike } = useIsLiked(tmdbId)
  const { isWishlisted, toggle: toggleWishlist } = useIsWishlisted(tmdbId)

  if (!tmdbId) return null

  const payload = buildPayload(item, tmdbId)

  const btnStyle = {
    width: 'clamp(20px,1.5vw,26px)',
    height: 'clamp(20px,1.5vw,26px)',
  }

  return (
    <div
      data-collection-btn
      className="absolute top-[clamp(4px,0.31vw,8px)] left-[clamp(4px,0.31vw,8px)] flex flex-col gap-[clamp(3px,0.2vw,5px)] z-10"
      onClick={(e) => e.stopPropagation()}
      onMouseDown={(e) => e.stopPropagation()}
      onPointerDown={(e) => e.stopPropagation()}
      onDoubleClick={(e) => e.stopPropagation()}
    >
      {/* Liked — mouse-only, keyboard users use context menu */}
      <button
        type="button"
        tabIndex={-1}
        onClick={(e) => { e.preventDefault(); e.stopPropagation(); toggleLike(payload) }}
        onMouseDown={(e) => e.stopPropagation()}
        onPointerDown={(e) => e.stopPropagation()}
        onDoubleClick={(e) => e.stopPropagation()}
        className={`flex items-center justify-center rounded-full backdrop-blur-sm transition-all duration-150 cursor-pointer ${
          isLiked
            ? 'opacity-100 bg-red-500/25 border border-red-500/60'
            : 'opacity-0 group-hover:opacity-100 bg-black/60 border border-white/20 hover:bg-black/80'
        }`}
        style={btnStyle}
        title={isLiked ? 'Unlike' : 'Like'}
      >
        <Heart
          size={iconSize}
          fill={isLiked ? 'currentColor' : 'none'}
          className={isLiked ? 'text-red-400' : 'text-white'}
        />
      </button>

      {/* Wishlist — mouse-only, keyboard users use context menu */}
      <button
        type="button"
        tabIndex={-1}
        onClick={(e) => { e.preventDefault(); e.stopPropagation(); toggleWishlist(payload) }}
        onMouseDown={(e) => e.stopPropagation()}
        onPointerDown={(e) => e.stopPropagation()}
        onDoubleClick={(e) => e.stopPropagation()}
        className={`flex items-center justify-center rounded-full backdrop-blur-sm transition-all duration-150 cursor-pointer ${
          isWishlisted
            ? 'opacity-100 bg-emerald-500/25 border border-emerald-500/60'
            : 'opacity-0 group-hover:opacity-100 bg-black/60 border border-white/20 hover:bg-black/80'
        }`}
        style={btnStyle}
        title={isWishlisted ? 'Remove from Wishlist' : 'Add to Wishlist'}
      >
        {isWishlisted
          ? <CheckCircle2 size={iconSize} className="text-emerald-400" />
          : <Plus size={iconSize} className="text-white" />
        }
      </button>
    </div>
  )
}
