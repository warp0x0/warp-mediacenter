import { useEffect, useMemo, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { X, Search, Download } from 'lucide-react'
import { downloadSubtitle, loadSubtitle, searchSubtitles } from '@/hooks/useSubtitles'
import type { SubtitleSearchResult } from '@/lib/types'

interface SubtitleDialogProps {
  open: boolean
  title: string
  mediaKind: 'movie' | 'show'
  onClose: () => void
  year?: number | null
  season?: number | null
  episode?: number | null
  onLoaded?: (path: string) => void
}

export default function SubtitleDialog({
  open,
  title,
  mediaKind,
  onClose,
  year,
  season,
  episode,
  onLoaded,
}: SubtitleDialogProps) {
  const [query, setQuery] = useState(title)
  const [results, setResults] = useState<SubtitleSearchResult[]>([])
  const [loading, setLoading] = useState(false)
  const [actioning, setActioning] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const lastActionAt = useRef(0)

  useEffect(() => {
    if (open) {
      setQuery(title)
      setResults([])
      setMessage(null)
    }
  }, [open, title])

  const statusText = useMemo(() => {
    if (loading) return 'Searching...'
    if (actioning) return 'Downloading subtitle...'
    return message
  }, [loading, actioning, message])

  async function doSearch() {
    if (!query.trim()) return
    setLoading(true)
    setMessage(null)
    try {
      const data = await searchSubtitles({
        query: query.trim(),
        mediaKind,
        year: year ?? undefined,
        season: season ?? undefined,
        episode: episode ?? undefined,
      })
      setResults(data.results)
    } catch (err) {
      setResults([])
      setMessage(err instanceof Error ? err.message : 'Subtitle search failed')
    } finally {
      setLoading(false)
    }
  }

  async function handlePick(result: SubtitleSearchResult) {
    const now = Date.now()
    if (now - lastActionAt.current < 250) return
    lastActionAt.current = now
    setActioning(true)
    setMessage(null)
    try {
      const downloaded = await downloadSubtitle(result)
      const loaded = await loadSubtitle({ id: downloaded.id })
      onLoaded?.(loaded.path)
      setMessage('Subtitle loaded')
      setTimeout(onClose, 1000)
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Subtitle download failed')
    } finally {
      setActioning(false)
    }
  }

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 z-50"
            onClick={onClose}
          />
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.97 }}
            className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-[clamp(320px,40vw,680px)] bg-bg-panel border border-white/10 backdrop-blur-xl rounded-card p-[clamp(16px,1.67vw,32px)] space-y-[clamp(12px,1.25vw,24px)]"
          >
            <div className="flex items-center justify-between gap-[clamp(8px,0.63vw,14px)]">
              <h2 className="text-section font-bold text-fg-white">Subtitles</h2>
              <button onClick={onClose} className="text-fg-muted hover:text-fg-primary cursor-pointer">
                <X size={20} />
              </button>
            </div>

            <div className="flex gap-[clamp(6px,0.52vw,12px)]">
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="flex-1 input-field text-subtitle"
                placeholder="Search subtitle release..."
              />
              <button onClick={doSearch} className="btn-primary cursor-pointer flex items-center gap-[clamp(4px,0.31vw,8px)]">
                <Search size={16} />
                Search
              </button>
            </div>

            {statusText && <p className="text-fg-muted text-subtitle">{statusText}</p>}

            <div className="max-h-[clamp(240px,30vh,420px)] overflow-y-auto space-y-[clamp(6px,0.52vw,12px)]">
              {results.map((result, idx) => (
                <button
                  key={`${result.provider}-${idx}`}
                  onDoubleClick={() => handlePick(result)}
                  onClick={() => handlePick(result)}
                  className="w-full text-left rounded-card border border-white/5 bg-white/[0.03] p-[clamp(10px,0.83vw,16px)] hover:bg-white/[0.05] transition-colors cursor-pointer"
                >
                  <div className="flex items-center justify-between gap-[clamp(8px,0.63vw,14px)]">
                    <div className="min-w-0">
                      <p className="text-fg-white font-medium truncate" style={{ fontSize: 'var(--body-size)' }}>
                        {result.file_name}
                      </p>
                      <p className="text-fg-muted truncate" style={{ fontSize: 'var(--subtitle-size)' }}>
                        {result.provider} • {result.language} • {result.release}
                      </p>
                    </div>
                    <div className="flex items-center gap-[clamp(4px,0.31vw,8px)] text-accent shrink-0">
                      <Download size={14} />
                      {Math.round(result.score * 100)}
                    </div>
                  </div>
                </button>
              ))}
              {!results.length && !loading && (
                <p className="text-fg-muted text-subtitle">No results yet.</p>
              )}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
