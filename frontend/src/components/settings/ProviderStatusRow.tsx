import type { ProviderStatus as ProviderStatusType } from '@/lib/types'

interface ProviderStatusRowProps {
  name: string
  status: ProviderStatusType | undefined
  isLoading: boolean
}

export default function ProviderStatusRow({ name, status, isLoading }: ProviderStatusRowProps) {
  const colorMap: Record<string, string> = {
    ok: 'bg-success',
    error: 'bg-danger',
    warning: 'bg-warning',
    unknown: 'bg-fg-muted',
  }

  const statusColor = status ? (colorMap[status.status] || 'bg-fg-muted') : 'bg-fg-muted'
  const statusLabel = status ? status.status : (isLoading ? 'loading' : 'unknown')

  return (
    <div className="flex items-center justify-between py-[clamp(4px,0.31vw,8px)]">
      <div className="flex items-center gap-[clamp(8px,0.63vw,14px)]">
        <div className={`w-[clamp(8px,0.52vw,10px)] h-[clamp(8px,0.52vw,10px)] rounded-full ${isLoading ? 'bg-fg-muted animate-pulse' : statusColor}`} />
        <p className="text-fg-white font-medium" style={{ fontSize: 'var(--body-size)' }}>{name}</p>
      </div>
      <div className="text-right">
        <p className="text-fg-muted capitalize" style={{ fontSize: 'var(--subtitle-size)' }}>
          {isLoading ? '...' : statusLabel}
          {status?.authenticated === true && ' (auth)'}
          {status?.api_key_configured === true && ' (key)'}
        </p>
        {status?.url && (
          <p className="text-fg-muted truncate max-w-[clamp(150px,12vw,260px)]"
             style={{ fontSize: 'var(--subtitle-size)' }}>{status.url}</p>
        )}
        {status?.error && (
          <p className="text-danger truncate max-w-[clamp(150px,12vw,260px)]"
             style={{ fontSize: 'var(--subtitle-size)' }}>{status.error}</p>
        )}
      </div>
    </div>
  )
}
