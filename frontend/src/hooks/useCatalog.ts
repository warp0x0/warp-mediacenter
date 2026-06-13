import type { CatalogResponse } from '@/lib/types'
import { useApi } from './useApi'

export function useCatalog(
  provider: string,
  category: string,
  mediaType: 'movie' | 'show',
  page?: number,
  limit?: number,
  offset?: number,
) {
  const params: Record<string, string> = { media_type: mediaType }
  if (page !== undefined) params.page = String(page)
  if (limit !== undefined) params.limit = String(limit)
  if (offset !== undefined) params.offset = String(offset)

  return useApi<CatalogResponse>(`/api/v1/catalog/${provider}/${category}`, params)
}
