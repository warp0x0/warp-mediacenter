import { Routes, Route } from 'react-router-dom'
import AppShell from '@/components/layout/AppShell'
import MoviesPage from '@/pages/MoviesPage'
import ShowsPage from '@/pages/ShowsPage'
import EpisodeGridPage from '@/pages/EpisodeGridPage'
import LocalDrivePage from '@/pages/LocalDrivePage'
import SettingsPage from '@/pages/SettingsPage'
import PowerPage from '@/pages/PowerPage'
import SearchPage from '@/pages/SearchPage'
import DetailViewPage from '@/pages/DetailViewPage'
import PlaybackPage from '@/pages/PlaybackPage'

export default function App() {
  return (
    <Routes>
      <Route element={<AppShell />}>
        <Route index element={<MoviesPage />} />
        <Route path="search" element={<SearchPage />} />
        <Route path="shows" element={<ShowsPage />} />
        <Route path="shows/:showId" element={<EpisodeGridPage />} />
        <Route path="local" element={<LocalDrivePage />} />
        <Route path="settings" element={<SettingsPage />} />
        <Route path="power" element={<PowerPage />} />
      </Route>
      <Route path="detail/:mediaId" element={<DetailViewPage />} />
      <Route path="playback" element={<PlaybackPage />} />
    </Routes>
  )
}
