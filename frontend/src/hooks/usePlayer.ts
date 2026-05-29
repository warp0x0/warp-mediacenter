import useSWR from 'swr'
import { apiGet, apiPost } from '@/lib/api'
import type { PlayerPlayRequest, PlayerStatus } from '@/lib/types'

export function usePlayerStatus() {
  return useSWR<PlayerStatus>('/api/v1/player/status', () => apiGet<PlayerStatus>('/api/v1/player/status'), {
    refreshInterval: 1000,
  })
}

export async function playMedia(data: PlayerPlayRequest): Promise<{ status: string; title: string }> {
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
