import useSWR, { type SWRConfiguration } from 'swr'
import { apiGet, apiPost } from '@/lib/api'
import { useApi } from './useApi'
import type {
  AuthStatus,
  TraktAuthStartResponse,
  TraktUserProfile,
  DebridAccountInfo,
} from '@/lib/types'

export function useAuthTrakt(config?: SWRConfiguration) {
  return useSWR<AuthStatus>(
    '/api/v1/trakt/auth/status',
    () => apiGet<AuthStatus>('/api/v1/trakt/auth/status'),
    { refreshInterval: 3000, ...config },
  )
}

export function useAuthDebrid(config?: SWRConfiguration) {
  return useSWR<AuthStatus>(
    '/api/v1/debrid/auth/status',
    () => apiGet<AuthStatus>('/api/v1/debrid/auth/status'),
    { refreshInterval: 3000, ...config },
  )
}

export function useTraktProfile() {
  return useApi<TraktUserProfile>('/api/v1/scrobble/user')
}

export function useDebridAccount(enabled: boolean = true) {
  return useApi<DebridAccountInfo>(enabled ? '/api/v1/debrid/account' : null)
}

export async function startTraktAuth(): Promise<TraktAuthStartResponse> {
  return apiPost<TraktAuthStartResponse>('/api/v1/trakt/auth/start')
}

export async function clearTraktAuth(): Promise<void> {
  await apiPost('/api/v1/trakt/auth/clear')
}

export async function clearDebridAuth(): Promise<void> {
  await apiPost('/api/v1/debrid/auth/clear')
}

export async function startDebridAuth(): Promise<{ user_code: string; verification_url: string; device_code: string }> {
  return apiPost<{ user_code: string; verification_url: string; device_code: string }>('/api/v1/debrid/auth/start')
}

export async function refreshDebridToken(): Promise<{ refreshed: boolean; authenticated: boolean; reason?: string; message?: string }> {
  return apiPost<{ refreshed: boolean; authenticated: boolean; reason?: string; message?: string }>('/api/v1/debrid/auth/refresh')
}
