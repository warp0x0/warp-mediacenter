import useSWR from 'swr'
import { apiDelete, apiGet, apiPost } from '@/lib/api'
import type {
  DebridStreamResponse,
  DebridTorrentInfo,
  TorrentResolveResponse,
  TorrentSearchRequest,
  TorrentSearchResponse,
  TorrentStatus,
} from '@/lib/types'

export async function searchTorrents(params: TorrentSearchRequest): Promise<TorrentSearchResponse> {
  return apiPost<TorrentSearchResponse>('/api/v1/torrent/search', params)
}

export function useTorrentStatus(torrentId: string | null) {
  return useSWR<TorrentStatus>(
    torrentId ? `/api/v1/torrent/status/${torrentId}` : null,
    () => apiGet<TorrentStatus>(`/api/v1/torrent/status/${torrentId!}`),
    { refreshInterval: 2000 },
  )
}

export async function resolveTorrent(data: {
  hash: string
  title_id?: number
  title?: string
  media_type?: string
  tmdb_id?: string
  season?: number
  episode?: number
  year?: number
}): Promise<TorrentResolveResponse> {
  return apiPost<TorrentResolveResponse>('/api/v1/torrent/resolve', {
    torrent_hash: data.hash,
    title: data.title,
    media_type: data.media_type,
    tmdb_id: data.tmdb_id,
    season: data.season,
    episode: data.episode,
    year: data.year,
  })
}

export function useDebridTorrentInfo(torrentId: string | null) {
  return useSWR<DebridTorrentInfo>(
    torrentId ? `/api/v1/debrid/torrent/${torrentId}` : null,
    () => apiGet<DebridTorrentInfo>(`/api/v1/debrid/torrent/${torrentId!}`),
  )
}

export async function getDebridStreamUrl(torrentId: string, fileId: number): Promise<DebridStreamResponse> {
  return apiGet<DebridStreamResponse>(`/api/v1/debrid/stream/${torrentId}/${fileId}`)
}

export async function deleteDebridTorrent(torrentId: string): Promise<void> {
  await apiDelete<unknown>(`/api/v1/debrid/torrent/${torrentId}`)
}
