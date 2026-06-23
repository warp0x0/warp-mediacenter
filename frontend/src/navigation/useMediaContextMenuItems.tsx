import { useCallback, useMemo } from 'react'
import { mutate } from 'swr'
import { CheckCircle2, Heart, Plus } from 'lucide-react'
import { markAsWatched } from '@/hooks/useLibrary'
import { useIsLiked, useIsWishlisted } from '@/hooks/useCollections'
import type { MediaItem, CollectionItemPayload } from '@/lib/types'
import type { NavContextMenuItem } from './NavigationProvider'

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

export function useMediaContextMenuItems(item: MediaItem): NavContextMenuItem[] {
  const tmdbId = item.tmdb_id ? String(item.tmdb_id) : null
  const { isLiked, toggle: toggleLike } = useIsLiked(tmdbId)
  const { isWishlisted, toggle: toggleWishlist } = useIsWishlisted(tmdbId)

  const toggleLikeAction = useCallback(async () => {
    await toggleLike(buildCollectionPayload(item))
  }, [item, toggleLike])

  const toggleWishlistAction = useCallback(async () => {
    await toggleWishlist(buildCollectionPayload(item))
  }, [item, toggleWishlist])

  const markWatchedAction = useCallback(async () => {
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
      // Trakt may not be configured; local menu action should still close.
    }
  }, [item])

  return useMemo(() => [
    {
      key: 'toggle-like',
      label: isLiked ? 'Unlike' : 'Like',
      icon: <Heart size={16} fill={isLiked ? 'currentColor' : 'none'} className={isLiked ? 'text-red-400' : ''} />,
      onSelect: toggleLikeAction,
    },
    {
      key: 'toggle-wishlist',
      label: isWishlisted ? 'Remove from Wishlist' : 'Add to Wishlist',
      icon: isWishlisted ? <CheckCircle2 size={16} className="text-emerald-400" /> : <Plus size={16} />,
      onSelect: toggleWishlistAction,
    },
    {
      key: 'mark-watched',
      label: 'Mark as Watched',
      icon: <CheckCircle2 size={16} />,
      onSelect: markWatchedAction,
    },
  ], [isLiked, isWishlisted, markWatchedAction, toggleLikeAction, toggleWishlistAction])
}
