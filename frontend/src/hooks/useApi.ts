import useSWR, { type SWRConfiguration } from 'swr'
import { apiGet } from '@/lib/api'

export function useApi<T>(
  path: string | null,
  params?: Record<string, string>,
  config?: SWRConfiguration,
) {
  return useSWR<T>(
    path ? [path, params] : null,
    () => apiGet<T>(path!, params),
    {
      revalidateOnFocus: false,
      errorRetryCount: 3,
      errorRetryInterval: 2000,
      ...config,
    },
  )
}
