import { useEffect } from 'react'
import { Outlet } from 'react-router-dom'
import TabBar from './TabBar'
import { refreshDebridToken } from '@/hooks/useAuth'

export default function AppShell() {
  // Attempt a silent RD token refresh on every app startup.
  // If the access_token has expired but a refresh_token is stored, this
  // transparently exchanges it for a new token before the user does anything.
  // Errors are intentionally swallowed — the user will see "Not authenticated"
  // in Settings and can reconnect manually if the refresh_token is also dead.
  useEffect(() => {
    refreshDebridToken().catch(() => {})
  }, [])

  return (
    <div className="h-screen w-screen bg-bg-primary overflow-hidden">
      <TabBar />

      <main className="h-full w-full">
        <Outlet />
      </main>
    </div>
  )
}
