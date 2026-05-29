import { useApi } from './useApi'
import { apiPut, apiPost } from '@/lib/api'
import type {
  SettingsResponse,
  ProvidersResponse,
  SettingsUpdateResponse,
  HealthResponse,
  ScanStatus,
  WidgetsConfigResponse,
  WidgetConfig,
  SaveWidgetsResponse,
} from '@/lib/types'

export function useSettings() {
  return useApi<SettingsResponse>('/api/v1/settings')
}

export function useProviders() {
  return useApi<ProvidersResponse>('/api/v1/settings/providers')
}

export function useHealth() {
  return useApi<HealthResponse>('/api/v1/health')
}

export function useScanStatus(scanId: string | null) {
  return useApi<ScanStatus>(
    scanId ? '/api/v1/settings/library/scan/status' : null,
    scanId ? { scan_id: scanId } : undefined,
  )
}

export async function updateSetting(key: string, value: string): Promise<SettingsUpdateResponse> {
  return apiPut<SettingsUpdateResponse>(`/api/v1/settings/${key}`, { value })
}

export async function updateCatalogMovies(config: unknown): Promise<SettingsUpdateResponse> {
  return apiPut<SettingsUpdateResponse>('/api/v1/settings/catalog_movies', { config })
}

export async function updateCatalogShows(config: unknown): Promise<SettingsUpdateResponse> {
  return apiPut<SettingsUpdateResponse>('/api/v1/settings/catalog_shows', { config })
}

export async function startLibraryScan(): Promise<{ scan_id: string; message: string }> {
  return apiPost('/api/v1/settings/library/scan')
}

// ---------------------------------------------------------------------------
// Widget configuration
// ---------------------------------------------------------------------------

export function useWidgets() {
  return useApi<WidgetsConfigResponse>('/api/v1/settings/widgets')
}

export async function saveWidgets(
  config: { movies?: WidgetConfig[]; shows?: WidgetConfig[] },
): Promise<SaveWidgetsResponse> {
  return apiPut<SaveWidgetsResponse>('/api/v1/settings/widgets', config)
}
