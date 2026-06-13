import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { AlertCircle, CheckCircle2, Loader2, Search, X, Magnet, Zap } from 'lucide-react'
import { apiGet, ApiError } from '@/lib/api'
import { getDebridStreamUrl, resolveTorrent, searchTorrents, useTorrentStatus } from '@/hooks/useTorrent'
import { createPreloadSession, stopPreloadSession, usePreloadSessionStatus } from '@/hooks/usePlayer'
import { refreshDebridToken } from '@/hooks/useAuth'
import type { DebridTorrentInfo, MediaItem, TorrentResult, TorrentStatus } from '@/lib/types'

interface TorrentDialogProps {
  open: boolean
  title: string
  mediaKind: 'movie' | 'tv'
  onClose: () => void
  item?: MediaItem | null
  season?: number | null
  episode?: number | null
  year?: number | null
  /** When set (0–100), the preload session begins downloading from this
   *  percentage of the file and the value is forwarded to onStreamReady
   *  so the caller can seek mpv to the resume position. */
  resumePercent?: number | null
  onStreamReady: (payload: {
    source: string
    /** StreamProxy loopback URL with real filename (e.g. http://127.0.0.1:9200/Movie.mkv).
     *  Native players on the same machine (mpv via Tauri) should prefer this over
     *  `source` because it carries a filename extension that the demuxer can use as a
     *  format hint and avoids the extra FastAPI proxy hop. */
    local_source?: string
    title: string
    isStream: boolean
    media_kind: 'movie' | 'tv'
    tmdb_id?: string | null
    year?: number | null
    season?: number | null
    episode?: number | null
    session_id?: string | null
    /** Forwarded from resumePercent prop — callers use this to compute seek position. */
    resumePercent?: number | null
  }) => void
}

// ── Status banner state ───────────────────────────────────────────────────────
type BannerKind = 'info' | 'progress' | 'success' | 'error'

interface BannerState {
  kind: BannerKind
  text: string
  subtext?: string
  /** When set (0–100) a filled progress bar is shown below the text. */
  progressPct?: number
}

export default function TorrentDialog({
  open,
  title,
  mediaKind,
  onClose,
  item,
  season,
  episode,
  year,
  resumePercent,
  onStreamReady,
}: TorrentDialogProps) {
  const [query, setQuery]         = useState(title)
  const [results, setResults]     = useState<TorrentResult[]>([])
  const [cachedCount, setCachedCount] = useState(0)
  const [loading, setLoading]     = useState(false)
  const [resolving, setResolving] = useState(false)
  const [banner, setBanner]       = useState<BannerState | null>(null)
  const [torrentId, setTorrentId] = useState<string | null>(null)
  const [_torrentInfo, setTorrentInfo] = useState<TorrentStatus | null>(null)
  const [hasSearched, setHasSearched] = useState(false)
  const [preloading, setPreloading] = useState(false)
  const [preloadSessionId, setPreloadSessionId] = useState<string | null>(null)
  const pendingStream = useRef<{
    source: string
    local_source?: string
    title: string
    isStream: boolean
    media_kind: 'movie' | 'tv'
    tmdb_id?: string | null
    year?: number | null
    season?: number | null
    episode?: number | null
    session_id?: string | null
    resumePercent?: number | null
  } | null>(null)
  const lastActionAt = useRef(0)

  const statusQuery = useTorrentStatus(torrentId)
  const preloadStatusQuery = usePreloadSessionStatus(preloadSessionId)

  useEffect(() => {
    if (open) {
      setQuery(title)
      setResults([])
      setCachedCount(0)
      setBanner(null)
      setHasSearched(false)
      setResolving(false)
      setTorrentId(null)
      setTorrentInfo(null)
      setPreloading(false)
      setPreloadSessionId(null)
      pendingStream.current = null
    }
  }, [open, title])

  useEffect(() => {
    if (open) return
    if (!preloadSessionId) return
    stopPreloadSession(preloadSessionId).catch(() => {})
  }, [open, preloadSessionId])

  // Reflect live torrent status into the banner while resolving
  useEffect(() => {
    if (!statusQuery.data || !torrentId) return
    const s = statusQuery.data
    setTorrentInfo(s)

    if (['downloaded', 'finished'].includes(s.status)) {
      setBanner({ kind: 'success', text: 'Stream ready — launching playback…' })
    } else if (['error', 'dead', 'unknown'].includes(s.status)) {
      setBanner({ kind: 'error', text: s.message || `Torrent ${s.status}` })
    } else {
      const parts: string[] = [`Status: ${s.status}`]
      if (s.progress != null) parts.push(`${s.progress}%`)
      if (s.speed && s.speed > 0) parts.push(`${(s.speed / 1024 / 1024).toFixed(1)} MB/s`)
      if (s.seeders && s.seeders > 0) parts.push(`${s.seeders} seeders`)
      setBanner({ kind: 'progress', text: 'Caching on Real-Debrid…', subtext: parts.join('  ·  ') })
    }
  }, [statusQuery.data, torrentId])

  // Drive the "Buffering…" banner from preload status and fire onStreamReady at 20%
  useEffect(() => {
    if (!preloading || !preloadStatusQuery.data) return
    const s = preloadStatusQuery.data
    if (s.state === 'error') {
      setPreloading(false)
      setPreloadSessionId(null)
      setBanner({ kind: 'error', text: 'Buffering failed', subtext: s.error || 'Unknown preload error' })
      return
    }

    const pct = s.percent

    const mbDl  = (s.bytes_downloaded / 1024 / 1024).toFixed(0)
    const denominator = (s.remaining_size ?? 0) > 0 ? s.remaining_size! : s.total_size
    const mbTot = denominator > 0 ? ` / ${(denominator / 1024 / 1024).toFixed(0)} MB` : ''

    setBanner({
      kind: 'progress',
      text: 'Downloading for smooth playback…',
      subtext: `${pct.toFixed(0)}%  ·  ${mbDl}${mbTot} MB`,
      progressPct: Math.min(pct, 100),
    })

    if (pct >= 20 || s.download_complete) {
      setPreloading(false)
      setPreloadSessionId(null)
      const payload = pendingStream.current
      pendingStream.current = null
      if (payload) {
        onStreamReady(payload)
        setTorrentId(null)
        onClose()
      }
    }
  }, [preloadStatusQuery.data, preloading, onStreamReady, onClose])

  // Episode tag for header subtitle
  const episodeTag =
    mediaKind === 'tv' && season != null
      ? ` · S${String(season).padStart(2, '0')}E${String(episode ?? 1).padStart(2, '0')}`
      : ''

  // ── Search ────────────────────────────────────────────────────────────────
  async function doSearch() {
    if (!query.trim()) return
    setLoading(true)
    setHasSearched(true)
    setBanner(null)
    setResults([])
    setCachedCount(0)
    try {
      const data = await searchTorrents({
        query: query.trim(),
        media_type: mediaKind,
        tmdb_id: item?.tmdb_id || undefined,
        season: season ?? undefined,
        episode: episode ?? undefined,
        year: year ?? undefined,
        limit: 24,
      })
      const cached = data.cached ?? []
      const uncached = data.uncached ?? []
      const merged = [...cached, ...uncached]
      setResults(merged)
      setCachedCount(cached.length)

      if (merged.length === 0) {
        setBanner({ kind: 'info', text: 'No results found — try a different query.' })
      } else {
        const parts = [`${merged.length} source${merged.length !== 1 ? 's' : ''} found`]
        if (cached.length > 0)   parts.push(`${cached.length} cached`)
        if (uncached.length > 0) parts.push(`${uncached.length} uncached`)
        setBanner({ kind: 'info', text: parts[0], subtext: parts.slice(1).join('  ·  ') || undefined })
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Torrent search failed'
      setBanner({ kind: 'error', text: 'Search failed', subtext: msg })
    } finally {
      setLoading(false)
    }
  }

  // ── Pick & resolve torrent ────────────────────────────────────────────────
  async function pickTorrent(result: TorrentResult) {
    const now = Date.now()
    if (now - lastActionAt.current < 250) return
    lastActionAt.current = now
    setResolving(true)
    setBanner({ kind: 'progress', text: `Resolving torrent…`, subtext: result.name })
    try {
      try { await refreshDebridToken() } catch { /* silent — resolve will surface auth errors */ }

      const resolved = await resolveTorrent({
        hash: result.hash,
        title,
        media_type: mediaKind,
        tmdb_id: item?.tmdb_id || undefined,
        season: season ?? undefined,
        episode: episode ?? undefined,
        year: year ?? undefined,
      })
      setTorrentId(resolved.torrent_id)
      // Banner updates come from the statusQuery effect above while we wait
      const stream = await waitForStream(resolved.torrent_id)
      if (!stream) throw new Error('Stream URL unavailable after download')

      // Store the payload for later, then start pre-buffering.
      // The preload effect above will fire onStreamReady once 20% is downloaded.
      const session = await createPreloadSession({
        stream_url: stream,
        title,
        media_kind: mediaKind,
        start_percent: resumePercent ?? undefined,
      })

      pendingStream.current = {
        source: session.playback_url,
        // StreamProxy URL with real filename — preferred by mpv (Tauri) for demux hint
        local_source: session.local_url,
        title,
        isStream: true,
        media_kind: mediaKind,
        tmdb_id: item?.tmdb_id || null,
        year,
        season,
        episode,
        session_id: session.session_id,
        resumePercent: resumePercent ?? null,
      }
      setTorrentId(null)   // stop the torrent status poll — we have the stream URL now
      setBanner({
        kind: 'progress',
        text: 'Downloading for smooth playback…',
        subtext: '0%',
        progressPct: 0,
      })
      setPreloadSessionId(session.session_id)
      setPreloading(true)  // activates preload session status polling
    } catch (err) {
      setTorrentId(null)
      setTorrentInfo(null)
      let headline = 'Torrent resolution failed'
      let detail: string | undefined

      if (err instanceof ApiError) {
        if (err.status === 401) {
          headline = 'Real-Debrid: Authentication required'
          detail = 'Go to Settings → Authentication → Real Debrid to re-authenticate.'
        } else if (err.status === 403) {
          headline = 'Real-Debrid: Access denied'
          detail = err.message
        } else {
          headline = `Real-Debrid error (${err.status})`
          detail = err.message
        }
      } else if (err instanceof Error) {
        // Surface the exact backend/status message verbatim
        const msg = err.message
        if (msg.toLowerCase().includes('infringing') || msg.toLowerCase().includes('dmca')) {
          headline = 'Real-Debrid: Infringing file blocked'
          detail = msg
        } else if (msg.toLowerCase().includes('timed out')) {
          headline = 'Timed out waiting for Real-Debrid'
          detail = 'The torrent may be slow or stuck — try another source.'
        } else if (msg.toLowerCase().includes('unavailable')) {
          headline = 'Stream URL unavailable'
          detail = msg
        } else {
          headline = msg
        }
      }

      setBanner({ kind: 'error', text: headline, subtext: detail })
    } finally {
      setResolving(false)
    }
  }

  async function waitForStream(id: string): Promise<string | null> {
    for (let i = 0; i < 20; i += 1) {
      const status = await apiGet<TorrentStatus>(`/api/v1/torrent/status/${id}`)
      setTorrentInfo(status)
      if (status.status === 'downloaded' || status.status === 'finished') {
        const info = await apiGet<DebridTorrentInfo>(`/api/v1/debrid/torrent/${id}`)
        const file = info.files.find((f) => f.selected) || info.files[0]
        if (!file) return null
        const stream = await getDebridStreamUrl(id, file.id)
        return stream.stream_url
      }
      if (['error', 'dead', 'unknown'].includes(status.status)) {
        throw new Error(status.message || `Torrent status: ${status.status}`)
      }
      await new Promise((r) => setTimeout(r, 3000))
    }
    throw new Error('Timed out waiting for Real-Debrid — torrent may be slow or unavailable.')
  }

  // ── Banner rendering ──────────────────────────────────────────────────────
  function renderBanner() {
    if (!banner) return null

    const colors: Record<BannerKind, { bg: string; border: string; textColor: string }> = {
      info:     { bg: 'rgba(255,255,255,0.04)', border: 'rgba(255,255,255,0.08)', textColor: 'rgba(255,255,255,0.60)' },
      progress: { bg: 'rgba(1,180,228,0.07)',   border: 'rgba(1,180,228,0.20)',   textColor: 'rgba(1,180,228,0.90)'  },
      success:  { bg: 'rgba(34,197,94,0.08)',   border: 'rgba(34,197,94,0.25)',   textColor: 'rgb(74,222,128)'       },
      error:    { bg: 'rgba(239,68,68,0.08)',   border: 'rgba(239,68,68,0.25)',   textColor: 'rgb(248,113,113)'      },
    }
    const c = colors[banner.kind]

    const Icon = () => {
      if (banner.kind === 'progress') return <Loader2 size={13} className="animate-spin shrink-0" />
      if (banner.kind === 'success')  return <CheckCircle2 size={13} className="shrink-0" />
      if (banner.kind === 'error')    return <AlertCircle size={13} className="shrink-0" />
      if (cachedCount > 0 && results.length > 0) return <Zap size={13} className="shrink-0" />
      return <Search size={13} className="shrink-0 opacity-60" />
    }

    return (
      <div
        className="shrink-0 flex flex-col gap-0 border-b"
        style={{
          padding: 'clamp(9px,1vh,13px) clamp(18px,1.5vw,28px)',
          background: c.bg,
          borderColor: c.border,
          color: c.textColor,
          fontSize: 'clamp(11px,0.65vw,13px)',
        }}
      >
        <div className="flex items-start gap-2">
          <span style={{ marginTop: 1 }}><Icon /></span>
          <span className="flex-1 min-w-0">
            <span className="font-semibold">{banner.text}</span>
            {banner.subtext && (
              <span className="block opacity-70 truncate" style={{ fontSize: '0.92em', marginTop: 1 }}>
                {banner.subtext}
              </span>
            )}
          </span>
        </div>
        {banner.progressPct !== undefined && (
          <div
            className="rounded-full overflow-hidden"
            style={{ height: 3, marginTop: 8, background: 'rgba(255,255,255,0.10)' }}
          >
            <div
              className="h-full rounded-full"
              style={{
                width: `${banner.progressPct}%`,
                background: 'var(--accent)',
                transition: 'width 0.6s ease',
              }}
            />
          </div>
        )}
      </div>
    )
  }

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50"
            style={{ background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(6px)', WebkitBackdropFilter: 'blur(6px)' }}
            onClick={onClose}
          />

          {/* Dialog */}
          <motion.div
            initial={{ opacity: 0, y: 24, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 24, scale: 0.97 }}
            transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
            className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50 flex flex-col overflow-hidden rounded-card border border-white/[0.09]"
            style={{
              width: 'clamp(520px, 62vw, 900px)',
              maxHeight: '82vh',
              background: 'rgba(10,10,14,0.97)',
              backdropFilter: 'blur(32px)',
              WebkitBackdropFilter: 'blur(32px)',
            }}
          >
            {/* Accent top stripe */}
            <div
              className="h-[3px] w-full shrink-0"
              style={{ background: 'linear-gradient(90deg, var(--accent) 0%, rgba(13,178,226,0.12) 100%)' }}
            />

            {/* ── HEADER ──────────────────────────────────────────────── */}
            <div
              className="flex items-center justify-between shrink-0 border-b border-white/[0.07]"
              style={{ padding: 'clamp(14px,1.6vh,22px) clamp(18px,1.5vw,28px)' }}
            >
              <div className="flex items-center gap-3">
                <div
                  className="flex items-center justify-center rounded-lg bg-accent/20 text-accent shrink-0"
                  style={{ width: 'clamp(34px,2.2vw,42px)', height: 'clamp(34px,2.2vw,42px)' }}
                >
                  <Magnet size={16} />
                </div>
                <div>
                  <h2 className="text-white font-bold" style={{ fontSize: 'clamp(14px,1vw,18px)' }}>
                    Search Sources
                  </h2>
                  <p className="text-white/35" style={{ fontSize: 'clamp(11px,0.65vw,13px)', marginTop: '1px' }}>
                    {title}{episodeTag}
                  </p>
                </div>
              </div>
              <button
                onClick={onClose}
                className="flex items-center justify-center rounded-lg text-white/35 hover:text-white/75 hover:bg-white/[0.07] transition-all duration-150 cursor-pointer shrink-0"
                style={{ width: 'clamp(30px,2vw,36px)', height: 'clamp(30px,2vw,36px)' }}
              >
                <X size={15} />
              </button>
            </div>

            {/* ── SEARCH BAR ──────────────────────────────────────────── */}
            <div
              className="flex gap-3 shrink-0 border-b border-white/[0.07]"
              style={{ padding: 'clamp(12px,1.4vh,18px) clamp(18px,1.5vw,28px)' }}
            >
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && doSearch()}
                className="flex-1 input-field"
                placeholder="Search sources…"
                style={{ fontSize: 'clamp(13px,0.8vw,15px)' }}
              />
              <button
                onClick={doSearch}
                disabled={loading || resolving}
                className="btn-primary flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60 shrink-0"
                style={{
                  padding: '0 clamp(16px,1.4vw,26px)',
                  height: 'clamp(36px,3.5vh,44px)',
                  fontSize: 'clamp(13px,0.8vw,15px)',
                }}
              >
                {loading ? <Loader2 size={15} className="animate-spin" /> : <Search size={15} />}
                {loading ? 'Searching…' : 'Search'}
              </button>
            </div>

            {/* ── STATUS BANNER (fixed — never scrolls) ───────────────── */}
            {renderBanner()}

            {/* ── SCROLLABLE BODY ─────────────────────────────────────── */}
            <div className="flex-1 overflow-y-auto" style={{ padding: 'clamp(12px,1.4vh,18px) clamp(18px,1.5vw,28px)' }}>

              {/* Idle state */}
              {!loading && !hasSearched && (
                <div className="flex flex-col items-center justify-center py-16 gap-3">
                  <div
                    className="flex items-center justify-center rounded-full bg-white/[0.04] text-white/20"
                    style={{ width: '56px', height: '56px' }}
                  >
                    <Magnet size={24} />
                  </div>
                  <p className="text-white/30 font-medium" style={{ fontSize: 'clamp(13px,0.85vw,15px)' }}>
                    Enter a query and press Search
                  </p>
                </div>
              )}

              {/* No results */}
              {hasSearched && !loading && results.length === 0 && (
                <div className="flex flex-col items-center justify-center py-16 gap-3">
                  <p className="text-white/30 font-medium text-center" style={{ fontSize: 'clamp(13px,0.85vw,15px)' }}>
                    No sources found. Try a different query.
                  </p>
                </div>
              )}

              {/* Results list */}
              {results.length > 0 && (
                <div className="flex flex-col" style={{ gap: 'clamp(6px,0.6vh,10px)' }}>
                  {results.map((result, idx) => {
                    const isCached = idx < cachedCount
                    return (
                      <button
                        key={result.hash}
                        onClick={() => pickTorrent(result)}
                        disabled={loading || resolving}
                        className="w-full text-left rounded-card border border-white/[0.06] transition-all duration-150 cursor-pointer disabled:opacity-40 group"
                        style={{
                          padding: 'clamp(10px,1vh,14px) clamp(14px,1.2vw,20px)',
                          background: 'rgba(255,255,255,0.025)',
                        }}
                        onMouseEnter={(e) => {
                          ;(e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.05)'
                          ;(e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(255,255,255,0.12)'
                        }}
                        onMouseLeave={(e) => {
                          ;(e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.025)'
                          ;(e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(255,255,255,0.06)'
                        }}
                      >
                        <div className="flex items-center justify-between gap-4">
                          <div className="min-w-0 flex-1">
                            <p
                              className="text-white/85 font-medium truncate"
                              style={{ fontSize: 'clamp(13px,0.82vw,15px)' }}
                            >
                              {result.name}
                            </p>
                            <div className="flex items-center gap-2 mt-[3px]" style={{ fontSize: 'clamp(11px,0.62vw,12px)' }}>
                              <span className="text-white/35">{result.seeders ?? 0} seeders</span>
                              <span className="text-white/20">·</span>
                              <span className="text-white/35">{result.size}</span>
                            </div>
                          </div>

                          <div className="flex items-center gap-2 shrink-0">
                            {isCached && (
                              <span
                                className="rounded-pill font-semibold"
                                style={{
                                  padding: '3px clamp(8px,0.7vw,12px)',
                                  fontSize: 'clamp(10px,0.6vw,12px)',
                                  background: 'rgba(34,197,94,0.15)',
                                  color: 'rgb(74,222,128)',
                                  border: '1px solid rgba(34,197,94,0.25)',
                                }}
                              >
                                ⚡ Cached
                              </span>
                            )}
                            {result.quality && (
                              <span
                                className="rounded-pill bg-accent/15 text-accent font-medium"
                                style={{
                                  padding: '3px clamp(8px,0.7vw,12px)',
                                  fontSize: 'clamp(10px,0.6vw,12px)',
                                }}
                              >
                                {result.quality}
                              </span>
                            )}
                          </div>
                        </div>
                      </button>
                    )
                  })}
                </div>
              )}

            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
