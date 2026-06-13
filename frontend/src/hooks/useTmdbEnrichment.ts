import { useMovieDetail, useShowDetail } from './useDetail'
import type { MediaItem } from '@/lib/types'
import { IMAGE_BASE } from '@/lib/constants'

export function useTmdbEnrichment(item: MediaItem, size: 'w300' | 'w342' | 'w500' = 'w500') {
  const needsEnrichment = !item.poster_path && !!item.tmdb_id
  const isShow = item.type === 'show'

  const movieDetail = useMovieDetail(needsEnrichment && !isShow ? item.tmdb_id : null)
  const showDetail = useShowDetail(needsEnrichment && isShow ? item.tmdb_id : null)
  const detail = isShow ? showDetail.data : movieDetail.data

  let posterUrl: string | null = null
  if (item.poster_path) {
    posterUrl = `${IMAGE_BASE}/${size}${item.poster_path}`
  } else if (detail?.poster?.url) {
    const p = detail.poster.url
    posterUrl = p.startsWith('/') ? `${IMAGE_BASE}/${size}${p}` : p
  } else if (item.poster?.url) {
    const p = item.poster.url
    posterUrl = p.startsWith('/') ? `${IMAGE_BASE}/${size}${p}` : p
  }

  const rating = item.rating ?? detail?.vote_average ?? null
  return { posterUrl, rating }
}
