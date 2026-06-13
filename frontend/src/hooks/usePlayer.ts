import useSWR from 'swr'
import { apiDelete, apiGet, apiPost } from '@/lib/api'
import type {
  PlayerPlayRequest,
  PlayerPlayResponse,
  PlayerScrobbleRequest,
  PlayerScrobbleResponse,
  PlayerStatus,
  PreloadSessionCreateRequest,
  PreloadSessionCreateResponse,
  PreloadSessionStatus,
} from '@/lib/types'

export function usePlayerStatus() {
  return useSWR<PlayerStatus>('/api/v1/player/status', () => apiGet<PlayerStatus>('/api/v1/player/status'), {
    refreshInterval: 1000,
  })
}

export async function playMedia(data: PlayerPlayRequest): Promise<PlayerPlayResponse> {
  return apiPost('/api/v1/player/play', data)
}

export async function pausePlayback(): Promise<{ message: string }> {
  return apiPost('/api/v1/player/pause')
}

export async function resumePlayback(): Promise<{ message: string }> {
  return apiPost('/api/v1/player/resume')
}

export async function stopPlayback(): Promise<{ message: string }> {
  return apiPost('/api/v1/player/stop')
}

export async function seekPlayback(positionMs: number): Promise<{ message: string }> {
  return apiPost('/api/v1/player/seek', { position_ms: positionMs })
}

export async function setVolume(volume: number): Promise<{ message: string }> {
  return apiPost('/api/v1/player/volume', { volume })
}

/**
 * Start a buffered preload session for a remote stream URL.
 */
export async function createPreloadSession(
  data: PreloadSessionCreateRequest,
): Promise<PreloadSessionCreateResponse> {
  return apiPost('/api/v1/player/preload/session', data)
}

/**
 * Poll preload progress for a specific session.
 * Pass `sessionId` as null to disable polling.
 */
export function usePreloadSessionStatus(sessionId: string | null) {
  return useSWR<PreloadSessionStatus>(
    sessionId ? `/api/v1/player/preload/session/${sessionId}/status` : null,
    () => apiGet<PreloadSessionStatus>(`/api/v1/player/preload/session/${sessionId!}/status`),
    { refreshInterval: 1000 },
  )
}

export async function stopPreloadSession(sessionId: string): Promise<{ session_id: string; removed: boolean }> {
  return apiDelete(`/api/v1/player/preload/session/${sessionId}`)
}

export async function scrobbleStart(payload: PlayerScrobbleRequest): Promise<PlayerScrobbleResponse> {
  return apiPost('/api/v1/player/scrobble/start', payload)
}

export async function scrobbleStop(payload: PlayerScrobbleRequest): Promise<PlayerScrobbleResponse> {
  return apiPost('/api/v1/player/scrobble/stop', payload)
}
