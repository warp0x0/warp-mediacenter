import { useState, useEffect } from 'react'
import { Routes, Route } from 'react-router-dom'
import AppShell from '@/components/layout/AppShell'
import MoviesPage from '@/pages/MoviesPage'
import ShowsPage from '@/pages/ShowsPage'
import EpisodeGridPage from '@/pages/EpisodeGridPage'
import LibraryPage from '@/pages/LibraryPage'
import SettingsPage from '@/pages/SettingsPage'
import PowerPage from '@/pages/PowerPage'
import SearchPage from '@/pages/SearchPage'
import DetailViewPage from '@/pages/DetailViewPage'
import CatalogBrowsePage from '@/pages/CatalogBrowsePage'
import LocalBrowsePage from '@/pages/LocalBrowsePage'
import PlaybackPage from '@/pages/PlaybackPage'
import HelpDialog from '@/components/shared/HelpDialog'
import { usePlaybackScrobble } from '@/hooks/usePlaybackScrobble'
import { refreshDebridToken } from '@/hooks/useAuth'
import { NavigationProvider } from '@/navigation/NavigationProvider'

export default function App() {
  usePlaybackScrobble()
  const [helpOpen, setHelpOpen] = useState(false)

  // Attempt a silent RD token refresh on every app startup.
  useEffect(() => {
    refreshDebridToken().catch(() => {})
  }, [])

  return (
    <NavigationProvider onToggleHelp={() => setHelpOpen((v) => !v)}>
      <Routes>
        <Route element={<AppShell />}>
          <Route index element={<MoviesPage />} />
          <Route path="search" element={<SearchPage />} />
          <Route path="shows" element={<ShowsPage />} />
          <Route path="shows/:showId" element={<EpisodeGridPage />} />
          <Route path="local" element={<LibraryPage />} />
          <Route path="settings" element={<SettingsPage />} />
          <Route path="power" element={<PowerPage />} />
          <Route path="catalog/:provider/:category" element={<CatalogBrowsePage />} />
          <Route path="local/browse" element={<LocalBrowsePage />} />
        </Route>
        <Route path="detail/:mediaId" element={<DetailViewPage />} />
        <Route path="playback" element={<PlaybackPage />} />
      </Routes>
      <HelpDialog open={helpOpen} onClose={() => setHelpOpen(false)} />
    </NavigationProvider>
  )
}
