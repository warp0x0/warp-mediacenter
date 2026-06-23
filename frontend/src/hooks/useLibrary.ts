import { useApi } from './useApi'
import { apiPost } from '@/lib/api'
import type {
  LibrarySection,
  LibrarySectionsResponse,
  LibraryTitleDetail,
  TitleSourcesResponse,
  TitleEpisodesResponse,
  LibrarySearchResponse,
} from '@/lib/types'

export function useLibrarySections() {
  return useApi<LibrarySectionsResponse>('/api/v1/library/sections')
}

export function useLibrarySearch(query: string | null) {
  const params = query ? { q: query } : undefined
  return useApi<LibrarySearchResponse>(query ? '/api/v1/library/search' : null, params)
}

export function useTitleDetail(titleId: number | string | null) {
  return useApi<LibraryTitleDetail>(
    titleId !== null ? `/api/v1/library/title/${titleId}` : null,
  )
}

export function useTitleSources(titleId: number | string | null, sourceType?: string) {
  const params = sourceType ? { source_type: sourceType } : undefined
  return useApi<TitleSourcesResponse>(
    titleId !== null ? `/api/v1/library/title/${titleId}/sources` : null,
    params,
  )
}

export function useTitleEpisodes(titleId: number | string | null, season?: number) {
  const params = season !== undefined ? { season: String(season) } : undefined
  return useApi<TitleEpisodesResponse>(
    titleId !== null ? `/api/v1/library/title/${titleId}/episodes` : null,
    params,
  )
}

export async function createLibrarySection(data: {
  name: string
  kind: string
  paths: string[]
}): Promise<LibrarySection> {
  return apiPost<LibrarySection>('/api/v1/library/sections', data)
}

export function useLibraryList(
  type: 'movies' | 'shows',
  params?: { sort?: string; order?: string; limit?: number; localOnly?: boolean },
) {
  const query: Record<string, string> = {}
  if (params?.sort) query.sort = params.sort
  if (params?.order) query.order = params.order
  if (params?.limit !== undefined) query.limit = String(params.limit)
  if (params?.localOnly) query.local_only = 'true'
  return useApi<import('@/lib/types').LibraryListResponse>(`/api/v1/library/${type}`, query)
}

export function useLibraryRecent(limit = 20) {
  return useApi<import('@/lib/types').LibraryListResponse>(
    '/api/v1/library/recent',
    { limit: String(limit) },
  )
}

export interface MarkWatchedResponse {
  ok: boolean
  title_id: number
  media_type: string
  local_recorded?: boolean
  trakt_synced: boolean
  trakt_history_synced?: boolean
  trakt_playback_removed?: boolean
  cache_invalidated?: boolean
  trakt_error: string | null
  errors?: string[]
}

export async function markAsWatched(payload: {
  tmdb_id: string
  media_type: 'movie' | 'show' | 'episode'
  season?: number
  episode?: number
  playback_id?: number
  title_id?: number
  title?: string
  year?: number | null
  overview?: string | null
  poster_path?: string | null
  backdrop_path?: string | null
  poster_url?: string | null
  backdrop_url?: string | null
}): Promise<MarkWatchedResponse> {
  return apiPost<MarkWatchedResponse>('/api/v1/library/mark-watched', payload)
}
