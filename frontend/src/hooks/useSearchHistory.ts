import { useState, useEffect, useCallback } from 'react'
import { apiGet, apiPost } from '@/lib/api'

export function useSearchHistory() {
  const [history, setHistory] = useState<string[]>([])

  useEffect(() => {
    apiGet<{ history: string[] }>('/api/v1/settings/search-history')
      .then((data) => setHistory(data.history))
      .catch(() => {})
  }, [])

  const addQuery = useCallback(async (query: string) => {
    try {
      const data = await apiPost<{ history: string[] }>('/api/v1/settings/search-history', { query })
      setHistory(data.history)
    } catch {}
  }, [])

  return { history, addQuery }
}
