import { useApi } from './useApi'
import type { MovieDetail, ShowDetail, ShowSeasonsResponse, ImdbRatingResponse, ShowProgressResponse } from '@/lib/types'

export function useMovieDetail(tmdbId: string | null, language?: string) {
  const params = language ? { language } : undefined
  return useApi<MovieDetail>(
    tmdbId ? `/api/v1/catalog/detail/movie/${tmdbId}` : null,
    params,
  )
}

export function useShowDetail(tmdbId: string | null, language?: string) {
  const params = language ? { language } : undefined
  return useApi<ShowDetail>(
    tmdbId ? `/api/v1/catalog/detail/show/${tmdbId}` : null,
    params,
  )
}

export function useShowSeasons(tmdbId: string | null, language?: string) {
  const params = language ? { language } : undefined
  return useApi<ShowSeasonsResponse>(
    tmdbId ? `/api/v1/catalog/show/${tmdbId}/seasons` : null,
    params,
  )
}

export function useImdbRating(imdbId: string | null | undefined) {
  return useApi<ImdbRatingResponse>(
    imdbId ? `/api/v1/catalog/imdb-rating/${imdbId}` : null,
  )
}

export function useShowProgress(tmdbId: string | null | undefined) {
  return useApi<ShowProgressResponse>(
    tmdbId ? `/api/v1/catalog/trakt/show_progress/${tmdbId}` : null,
  )
}
