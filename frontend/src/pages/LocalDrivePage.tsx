import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { FolderSearch, Play, Plus, HardDrive } from 'lucide-react'
import { useLibrarySections, useLibrarySearch, createLibrarySection } from '@/hooks/useLibrary'
import { useScanStatus, startLibraryScan, useSettings } from '@/hooks/useSettings'
import CatalogRow from '@/components/cards/CatalogRow'
import FileBrowser from '@/components/media/FileBrowser'
import type { LibrarySearchItem, MediaItem } from '@/lib/types'

function toMediaItem(item: LibrarySearchItem): MediaItem {
  return {
    id: String(item.id),
    title: item.title,
    type: item.type === 'tv' ? 'show' : 'movie',
    source_tag: 'local',
    year: item.year,
    overview: item.overview,
    poster: null,
    license: null,
    rating: null,
    genres: [],
    origin_country: null,
    external_url: null,
    extra: {},
    poster_path: item.poster_path,
    backdrop_path: item.backdrop_path,
    tmdb_id: item.tmdb_id,
    trakt_id: null,
    media: {
      id: String(item.id),
      title: item.title,
      name: item.title,
      year: item.year,
      overview: item.overview,
      poster_path: item.poster_path,
      backdrop_path: item.backdrop_path,
      rating: null,
      genres: [],
    },
  }
}

export default function LocalDrivePage() {
  const navigate = useNavigate()
  const { data: sectionsData, mutate: mutateSections } = useLibrarySections()
  const { data: settingsData } = useSettings()

  const [scanId, setScanId] = useState<string | null>(null)
  const [filterType, setFilterType] = useState<'all' | 'movie' | 'tv'>('all')
  const [sectionName, setSectionName] = useState('')
  const [sectionKind, setSectionKind] = useState<'movie' | 'tv'>('movie')
  const [scanMessage, setScanMessage] = useState<string | null>(null)

  const scanQuery = useScanStatus(scanId)
  const moviesQuery = useLibrarySearch(filterType === 'all' || filterType === 'movie' ? '' : null)
  const showsQuery = useLibrarySearch(filterType === 'all' || filterType === 'tv' ? '' : null)

  const sections = sectionsData?.sections ?? []
  const scanPaths = settingsData?.settings.library_scan_paths ?? ''
  const pathsList = scanPaths ? scanPaths.split(',').map((p: string) => p.trim()).filter(Boolean) : []

  useEffect(() => {
    if (scanQuery.data) {
      const status = scanQuery.data
      setScanMessage(
        `${status.current_file || 'Scanning...'} (${status.titles_added} added, ${status.titles_updated} updated)`,
      )
      if (status.done) {
        setScanId(null)
        setScanMessage('Scan complete.')
      }
    }
  }, [scanQuery.data])

  const handleScan = useCallback(async () => {
    try {
      const result = await startLibraryScan()
      setScanId(result.scan_id)
      setScanMessage('Starting scan...')
    } catch {
      setScanMessage('Failed to start scan')
    }
  }, [])

  const handleAddSection = useCallback(async () => {
    if (!sectionName.trim()) return
    try {
      await createLibrarySection({
        name: sectionName.trim(),
        kind: sectionKind,
        paths: [''],
      })
      setSectionName('')
      mutateSections()
    } catch {
      /* noop */
    }
  }, [sectionName, sectionKind, mutateSections])

  return (
    <div className="flex h-full overflow-hidden">
      <div
        className="flex flex-col gap-[clamp(12px,1.25vw,24px)] overflow-y-auto p-[clamp(12px,1.25vw,24px)] border-r border-white/5 shrink-0"
        style={{ width: 'clamp(240px, 18vw, 340px)' }}
      >
        <section className="rounded-card border border-white/5 bg-bg-panel p-[clamp(10px,0.83vw,16px)]"
                 style={{ gap: 'clamp(8px, 0.63vw, 14px)' }}>
          <h2 className="text-fg-white font-bold flex items-center gap-[clamp(6px,0.52vw,12px)]"
              style={{ fontSize: 'var(--section-title-size)' }}>
            <FolderSearch size={18} /> Library Scan
          </h2>

          {pathsList.map((p) => (
            <div key={p} className="text-fg-muted truncate" style={{ fontSize: 'var(--subtitle-size)' }}>
              <FileBrowser path={p} />
            </div>
          ))}
          {!pathsList.length && (
            <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
              No scan paths configured. Add paths in Settings.
            </p>
          )}

          <button
            onClick={handleScan}
            className="btn-primary w-full flex items-center justify-center gap-[clamp(4px,0.31vw,8px)] cursor-pointer"
          >
            <Play size={14} /> Scan Now
          </button>

          {scanMessage && (
            <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>{scanMessage}</p>
          )}
          {scanId && scanQuery.data && (
            <div className="h-[clamp(4px,0.31vw,6px)] rounded-full bg-white/10 overflow-hidden">
              <div
                className="h-full bg-accent rounded-full transition-all"
                style={{
                  width: `${scanQuery.data.titles_added ? Math.min(100, (scanQuery.data.titles_added / Math.max(1, scanQuery.data.files_found || 1)) * 100) : 0}%`,
                }}
              />
            </div>
          )}
        </section>

        <section className="rounded-card border border-white/5 bg-bg-panel p-[clamp(10px,0.83vw,16px)]"
                 style={{ gap: 'clamp(8px, 0.63vw, 14px)' }}>
          <h2 className="text-fg-white font-bold flex items-center gap-[clamp(6px,0.52vw,12px)]"
              style={{ fontSize: 'var(--section-title-size)' }}>
            <HardDrive size={18} /> Library Sections
          </h2>

          <div style={{ gap: 'clamp(4px, 0.31vw, 8px)' }}>
            {sections.map((section) => (
              <div
                key={section.id}
                className="flex items-center justify-between px-[clamp(6px,0.52vw,12px)] py-[clamp(4px,0.31vw,8px)] rounded-btn hover:bg-white/5"
              >
                <div>
                  <p className="text-fg-white font-medium" style={{ fontSize: 'var(--subtitle-size)' }}>
                    {section.name}
                  </p>
                  <p className="text-fg-muted" style={{ fontSize: 'clamp(10px,0.63vw,13px)' }}>
                    {section.kind} • {section.paths.length} path{section.paths.length !== 1 ? 's' : ''}
                  </p>
                </div>
              </div>
            ))}
          </div>

          <div className="flex gap-[clamp(4px,0.31vw,8px)]">
            <input
              value={sectionName}
              onChange={(e) => setSectionName(e.target.value)}
              className="flex-1 input-field text-subtitle"
              placeholder="Section name..."
            />
            <select
              value={sectionKind}
              onChange={(e) => setSectionKind(e.target.value as 'movie' | 'tv')}
              className="bg-white/5 text-fg-primary border border-white/10 rounded-input px-[clamp(8px,0.63vw,14px)] text-subtitle cursor-pointer"
            >
              <option value="movie">Movies</option>
              <option value="tv">TV Shows</option>
            </select>
            <button
              onClick={handleAddSection}
              className="btn-primary flex items-center gap-[clamp(4px,0.31vw,8px)] cursor-pointer"
            >
              <Plus size={14} /> Add
            </button>
          </div>
        </section>
      </div>

      <div className="h-full overflow-y-auto p-[clamp(12px,1.25vw,24px)]">
        <div className="flex items-center justify-between mb-[clamp(12px,1.25vw,24px)]">
          <h1
            className="font-extrabold text-fg-white tracking-tight"
            style={{ fontSize: 'var(--page-title-size)' }}
          >
            Local Library
          </h1>
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value as 'all' | 'movie' | 'tv')}
            className="bg-white/5 text-fg-primary border border-white/10 rounded-input px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] text-body cursor-pointer"
          >
            <option value="all">All Types</option>
            <option value="movie">Movies</option>
            <option value="tv">TV Shows</option>
          </select>
        </div>

        {moviesQuery.data && moviesQuery.data.items.length > 0 && (
          <CatalogRow
            title={`Movies (${moviesQuery.data.count})`}
            items={moviesQuery.data.items.map(toMediaItem)}
            onCardSelect={() => {}}
            onCardNavigate={(item) => navigate(`/detail/${item.tmdb_id || item.id}`, { state: { item } })}
          />
        )}

        {showsQuery.data && showsQuery.data.items.length > 0 && (
          <CatalogRow
            title={`Shows (${showsQuery.data.count})`}
            items={showsQuery.data.items.map(toMediaItem)}
            onCardSelect={() => {}}
            onCardNavigate={(item) => navigate(`/shows/${item.tmdb_id || item.id}`, { state: { item } })}
          />
        )}

        {(!moviesQuery.data?.items.length && !showsQuery.data?.items.length) && (
          <div className="flex flex-col items-center justify-center py-[clamp(40px,8vh,80px)] text-fg-muted">
            <FolderSearch size={40} className="mb-[clamp(12px,1.25vw,24px)] opacity-30" />
            <p style={{ fontSize: 'var(--body-size)' }}>No library items yet.</p>
            <p style={{ fontSize: 'var(--subtitle-size)' }}>Add media folders in Settings and run a scan.</p>
          </div>
        )}
      </div>
    </div>
  )
}
