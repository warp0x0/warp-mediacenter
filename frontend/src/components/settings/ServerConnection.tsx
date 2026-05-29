import { useState } from 'react'
import { CheckCircle, XCircle, Loader2 } from 'lucide-react'
import { apiGet } from '@/lib/api'
import type { HealthResponse } from '@/lib/types'

export default function ServerConnection() {
  const [url, setUrl] = useState('http://localhost:8000')
  const [testing, setTesting] = useState(false)
  const [result, setResult] = useState<'ok' | 'error' | null>(null)

  async function handleTest() {
    setTesting(true)
    setResult(null)
    try {
      const data = await apiGet<HealthResponse>('/api/v1/health')
      setResult(data.status === 'ok' || data.status === 'degraded' ? 'ok' : 'error')
    } catch {
      setResult('error')
    }
    setTesting(false)
  }

  return (
    <div style={{ gap: 'clamp(8px, 0.63vw, 14px)' }}>
      <div className="flex items-center gap-[clamp(6px,0.52vw,12px)]">
        <label className="text-fg-muted shrink-0" style={{ fontSize: 'var(--subtitle-size)' }}>
          Server URL
        </label>
        <input
          type="text"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          className="flex-1 input-field text-subtitle"
        />
        <button
          onClick={handleTest}
          disabled={testing}
          className="btn-primary text-subtitle px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] cursor-pointer disabled:opacity-50"
        >
          {testing ? <Loader2 size={15} className="animate-spin" /> : 'Test'}
        </button>
      </div>
      {result === 'ok' && (
        <div className="flex items-center gap-[clamp(4px,0.31vw,8px)] text-success" style={{ fontSize: 'var(--subtitle-size)' }}>
          <CheckCircle size={15} />
          Connected successfully
        </div>
      )}
      {result === 'error' && (
        <div className="flex items-center gap-[clamp(4px,0.31vw,8px)] text-danger" style={{ fontSize: 'var(--subtitle-size)' }}>
          <XCircle size={15} />
          Connection failed
        </div>
      )}
    </div>
  )
}
