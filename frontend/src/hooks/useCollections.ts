import { useCallback, useState } from 'react'
import useSWR from 'swr'
import { apiGet, apiPost, apiDelete } from '@/lib/api'
import type {
  CollectionResponse,
  CollectionStatusResponse,
  CollectionItemPayload,
  UserCollection,
} from '@/lib/types'

// ---------------------------------------------------------------------------
// Status hooks (used by DetailViewPage heart / plus buttons)
// ---------------------------------------------------------------------------

export function useIsLiked(tmdbId: string | null) {
  const key = tmdbId ? `/api/v1/collections/liked/${tmdbId}/status` : null

  const { data, mutate, isLoading } = useSWR<CollectionStatusResponse>(
    key,
    () => apiGet<CollectionStatusResponse>(key!),
    { revalidateOnFocus: false, errorRetryCount: 2 },
  )

  const toggle = useCallback(
    async (payload?: CollectionItemPayload) => {
      if (!tmdbId) return
      const currently = data?.in_collection ?? false
      // Optimistic update
      mutate({ tmdb_id: tmdbId, in_collection: !currently }, false)
      try {
        if (currently) {
          await apiDelete(`/api/v1/collections/liked/${tmdbId}`)
        } else if (payload) {
          await apiPost('/api/v1/collections/liked', payload)
        }
      } finally {
        mutate()
      }
    },
    [data, mutate, tmdbId],
  )

  return {
    isLiked: data?.in_collection ?? false,
    isLoading,
    toggle,
  }
}

export function useIsWishlisted(tmdbId: string | null) {
  const key = tmdbId ? `/api/v1/collections/wishlist/${tmdbId}/status` : null

  const { data, mutate, isLoading } = useSWR<CollectionStatusResponse>(
    key,
    () => apiGet<CollectionStatusResponse>(key!),
    { revalidateOnFocus: false, errorRetryCount: 2 },
  )

  const toggle = useCallback(
    async (payload?: CollectionItemPayload) => {
      if (!tmdbId) return
      const currently = data?.in_collection ?? false
      mutate({ tmdb_id: tmdbId, in_collection: !currently }, false)
      try {
        if (currently) {
          await apiDelete(`/api/v1/collections/wishlist/${tmdbId}`)
        } else if (payload) {
          await apiPost('/api/v1/collections/wishlist', payload)
        }
      } finally {
        mutate()
      }
    },
    [data, mutate, tmdbId],
  )

  return {
    isWishlisted: data?.in_collection ?? false,
    isLoading,
    toggle,
  }
}

// ---------------------------------------------------------------------------
// Paginated collection list (used by LikedSubTab / WishlistSubTab)
// ---------------------------------------------------------------------------

export type CollectionSort = 'added_at' | 'title' | 'rating' | 'vote_count'
export type CollectionOrder = 'asc' | 'desc'

interface UseCollectionOptions {
  collectionType: 'liked' | 'wishlist'
  mediaType?: 'movie' | 'show' | null
  sort?: CollectionSort
  order?: CollectionOrder
  genre?: string | null
  limit?: number
}

interface UseCollectionReturn {
  items: UserCollection[]
  total: number
  isLoading: boolean
  hasMore: boolean
  loadMore: () => Promise<void>
  reload: () => void
}

export function useCollection({
  collectionType,
  mediaType,
  sort = 'added_at',
  order = 'desc',
  genre,
  limit = 20,
}: UseCollectionOptions): UseCollectionReturn {
  const [items, setItems] = useState<UserCollection[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [isLoadingMore, setIsLoadingMore] = useState(false)

  const params: Record<string, string> = {
    sort,
    order,
    limit: String(limit),
    page: '1',
  }
  if (mediaType) params.type = mediaType
  if (genre) params.genre = genre

  const swrKey = [
    `/api/v1/collections/${collectionType}`,
    mediaType ?? '',
    sort,
    order,
    genre ?? '',
  ]

  const { isLoading, mutate } = useSWR<CollectionResponse>(
    swrKey,
    () =>
      apiGet<CollectionResponse>(`/api/v1/collections/${collectionType}`, params),
    {
      revalidateOnFocus: false,
      onSuccess: (data) => {
        setItems(data.items)
        setTotal(data.count)
        setPage(1)
      },
    },
  )

  const loadMore = useCallback(async () => {
    if (isLoadingMore) return
    const nextPage = page + 1
    setIsLoadingMore(true)
    try {
      const nextParams: Record<string, string> = {
        sort,
        order,
        limit: String(limit),
        page: String(nextPage),
      }
      if (mediaType) nextParams.type = mediaType
      if (genre) nextParams.genre = genre

      const data = await apiGet<CollectionResponse>(
        `/api/v1/collections/${collectionType}`,
        nextParams,
      )
      setItems((prev) => [...prev, ...data.items])
      setTotal(data.count)
      setPage(nextPage)
    } finally {
      setIsLoadingMore(false)
    }
  }, [collectionType, genre, isLoadingMore, limit, mediaType, order, page, sort])

  const reload = useCallback(() => {
    mutate()
  }, [mutate])

  return {
    items,
    total,
    isLoading: isLoading || isLoadingMore,
    hasMore: items.length < total,
    loadMore,
    reload,
  }
}
