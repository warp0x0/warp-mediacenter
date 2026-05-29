import { useState } from 'react'
import { UserCheck, UserX, Loader2 } from 'lucide-react'
import { useAuthTrakt, useAuthDebrid, clearTraktAuth, clearDebridAuth, useTraktProfile, useDebridAccount, refreshDebridToken } from '@/hooks/useAuth'
import AuthDialog from './AuthDialog'

type ProviderType = 'trakt' | 'debrid'

interface AuthPanelProps {
  type: ProviderType
}

export default function AuthPanel({ type }: AuthPanelProps) {
  const [dialogOpen, setDialogOpen] = useState(false)

  const traktStatus = useAuthTrakt()
  const debridStatus = useAuthDebrid()
  const traktProfile = useTraktProfile()
  const debridAccount = useDebridAccount(debridStatus.data?.authenticated ?? false)

  const statusData = type === 'trakt' ? traktStatus.data : debridStatus.data
  const profileData = type === 'trakt' ? traktProfile.data : debridAccount.data
  const isLoading = type === 'trakt' ? traktStatus.isLoading : debridStatus.isLoading
  const isAuth = statusData?.authenticated ?? false
  const label = type === 'trakt' ? 'Trakt' : 'Real Debrid'
  const [connecting, setConnecting] = useState(false)

  async function handleDisconnect() {
    if (type === 'trakt') {
      await clearTraktAuth()
    } else if (type === 'debrid') {
      await clearDebridAuth()
    }
    traktStatus.mutate()
    debridStatus.mutate()
  }

  async function handleConnect() {
    if (type === 'debrid') {
      setConnecting(true)
      try {
        const result = await refreshDebridToken()
        if (result.refreshed || result.authenticated) {
          debridStatus.mutate()
          return
        }
      } catch {
        // fall through to dialog
      } finally {
        setConnecting(false)
      }
    }
    setDialogOpen(true)
  }

  return (
    <>
      <div className="flex items-center justify-between py-[clamp(4px,0.31vw,8px)]">
        <div className="flex items-center gap-[clamp(8px,0.63vw,14px)]">
          <div className={`w-[clamp(8px,0.52vw,10px)] h-[clamp(8px,0.52vw,10px)] rounded-full ${isAuth ? 'bg-success' : 'bg-fg-muted'}`} />
          <div>
            <p className="text-fg-white font-medium" style={{ fontSize: 'var(--body-size)' }}>
              {label}
            </p>
            {isLoading ? (
              <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>Checking...</p>
            ) : isAuth ? (
              <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
                Authenticated
                {profileData && 'vip' in profileData && (
                  <span> | User: {profileData.username} | VIP: {profileData.vip ? 'Yes' : 'No'}</span>
                )}
                {profileData && 'premium' in profileData && (
                  <span> | Premium: {profileData.premium > 0 ? 'Yes' : 'No'}</span>
                )}
              </p>
            ) : (
              <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
                Not authenticated
              </p>
            )}
          </div>
        </div>

        {isAuth ? (
          <button
            onClick={handleDisconnect}
            className="flex items-center gap-[clamp(4px,0.31vw,8px)] text-subtitle text-danger hover:text-white hover:bg-danger/20 rounded-btn px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] transition-colors cursor-pointer"
          >
            <UserX size={15} />
            Disconnect
          </button>
        ) : (
          <button
            onClick={handleConnect}
            disabled={connecting}
            className="flex items-center gap-[clamp(4px,0.31vw,8px)] text-subtitle text-accent hover:text-accent-hover rounded-btn px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] transition-colors cursor-pointer disabled:opacity-50"
          >
            {connecting ? (
              <Loader2 size={15} className="animate-spin" />
            ) : (
              <UserCheck size={15} />
            )}
            {connecting ? 'Refreshing...' : 'Connect'}
          </button>
        )}
      </div>

      <AuthDialog
        open={dialogOpen}
        type={type}
        onClose={() => setDialogOpen(false)}
      />
    </>
  )
}
