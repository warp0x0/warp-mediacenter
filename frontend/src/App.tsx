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
import PlaybackPage from '@/pages/PlaybackPage'
import { usePlaybackScrobble } from '@/hooks/usePlaybackScrobble'

export default function App() {
  usePlaybackScrobble()

  return (
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
      </Route>
      <Route path="detail/:mediaId" element={<DetailViewPage />} />
      <Route path="playback" element={<PlaybackPage />} />
    </Routes>
  )
}
