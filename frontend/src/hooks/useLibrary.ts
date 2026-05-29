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
