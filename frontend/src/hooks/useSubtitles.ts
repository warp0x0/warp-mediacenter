import useSWR from 'swr'
import { apiGet, apiPost } from '@/lib/api'
import type {
  SubtitleDownloadResponse,
  SubtitleLoadResponse,
  SubtitleSearchResponse,
  SubtitleSearchResult,
} from '@/lib/types'

export function useSubtitleSearch(
  query: string | null,
  mediaKind: 'movie' | 'show' = 'movie',
  language = 'eng',
  season?: number,
  episode?: number,
  year?: number,
) {
  const params: Record<string, string> = { media_kind: mediaKind, language }
  if (season !== undefined) params.season = String(season)
  if (episode !== undefined) params.episode = String(episode)
  if (year !== undefined) params.year = String(year)

  return useSWR<SubtitleSearchResponse>(
    query ? ['/api/v1/subtitles/search', query, mediaKind, language, season, episode, year] : null,
    () => apiGet<SubtitleSearchResponse>('/api/v1/subtitles/search', { query: query!, ...params }),
    { revalidateOnFocus: false },
  )
}

export async function searchSubtitles(params: {
  query: string
  mediaKind?: 'movie' | 'show'
  language?: string
  season?: number
  episode?: number
  year?: number
}): Promise<SubtitleSearchResponse> {
  const q: Record<string, string> = {
    query: params.query,
    media_kind: params.mediaKind ?? 'movie',
    language: params.language ?? 'eng',
  }
  if (params.season !== undefined) q.season = String(params.season)
  if (params.episode !== undefined) q.episode = String(params.episode)
  if (params.year !== undefined) q.year = String(params.year)
  return apiGet<SubtitleSearchResponse>('/api/v1/subtitles/search', q)
}

export async function downloadSubtitle(result: SubtitleSearchResult): Promise<SubtitleDownloadResponse> {
  return apiPost<SubtitleDownloadResponse>('/api/v1/subtitles/download', result)
}

export async function loadSubtitle(payload: { id?: string; path?: string }): Promise<SubtitleLoadResponse> {
  return apiPost<SubtitleLoadResponse>('/api/v1/subtitles/load', payload)
}
