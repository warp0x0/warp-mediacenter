import { useState, useEffect, useCallback, useRef } from 'react'
import { Folder, Play, CheckCircle2, AlertCircle, Loader2, Film, Tv } from 'lucide-react'
import { apiGet, apiPost } from '@/lib/api'
import FileBrowserModal from './FileBrowserModal'
import { useFocusTrap } from '@/hooks/useFocusTrap'
import type { ScanStatusResponse } from '@/lib/types'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type PanelStatus = 'idle' | 'scanning' | 'cancelling' | 'complete' | 'error'

interface PanelState {
  folder: string | null
  status: PanelStatus
  logs: string[]
  error: string | null
  filesDone: number
  filesTotal: number
}

const defaultPanel = (): PanelState => ({
  folder: null,
  status: 'idle',
  logs: [],
  error: null,
  filesDone: 0,
  filesTotal: 0,
})

interface Props {
  open: boolean
  onClose: () => void
  onAddToLibrary: () => void
}

// ---------------------------------------------------------------------------
// ScanPanel — one of the two side-by-side panels
// ---------------------------------------------------------------------------

interface ScanPanelProps {
  label: string
  Icon: React.ElementType
  state: PanelState
  isOtherScanning: boolean
  onSelectFolder: () => void
  onScanNow: () => void
}

function ScanPanel({ label, Icon, state, isOtherScanning, onSelectFolder, onScanNow }: ScanPanelProps) {
  const logEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    logEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [state.logs])

  const scanDisabled =
    !state.folder || state.status === 'scanning' || isOtherScanning

  return (
    <div className="flex flex-col gap-4 flex-1 min-w-0">
      {/* Panel header */}
      <div className="flex items-center gap-2">
        <Icon size={16} className="text-white/60" />
        <span className="font-semibold text-white/90" style={{ fontSize: 15 }}>
          {label}
        </span>
        {state.status === 'complete' && (
          <CheckCircle2 size={15} className="text-emerald-400 ml-auto" />
        )}
        {state.status === 'error' && (
          <AlertCircle size={15} className="text-red-400 ml-auto" />
        )}
      </div>

      {/* Folder selector */}
      <button
        onClick={onSelectFolder}
        className="flex items-center gap-2 rounded-lg border text-sm transition-colors cursor-pointer hover:border-white/20 hover:bg-white/5"
        style={{
          padding: '8px 12px',
          borderColor: state.folder ? 'rgba(255,255,255,0.15)' : 'rgba(255,255,255,0.08)',
          background: state.folder ? 'rgba(255,255,255,0.04)' : 'transparent',
          // width: '2000px',
          // height: '140px'
        }}
      >
        <Folder size={14} className="text-amber-400/70 flex-shrink-0" />
        <span className={`truncate ${state.folder ? 'text-white/80' : 'text-white/35'}`}>
          {state.folder ?? `Select ${label} Folder…`}
        </span>
      </button>

      {/* Scan Now button */}
      <button
        onClick={onScanNow}
        disabled={scanDisabled}
        className="flex items-center justify-center gap-2 rounded-lg font-semibold text-sm transition-all cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
        style={{
          padding: '9px 0',
          background: state.status === 'scanning' ? 'rgba(255,255,255,0.08)' : 'var(--accent)',
          color: state.status === 'scanning' ? 'rgba(255,255,255,0.6)' : '#000',
          border: state.status === 'scanning' ? '1px solid rgba(255,255,255,0.10)' : 'none',
        }}
      >
        {state.status === 'scanning' ? (
          <>
            <Loader2 size={14} className="animate-spin" />
            Scanning…
          </>
        ) : (
          <>
            <Play size={14} fill="currentColor" />
            Scan Now
          </>
        )}
      </button>

      {/* Progress bar */}
      {(state.status === 'scanning' || state.status === 'cancelling' || state.status === 'complete') && (
        <div>
          <div className="flex items-center justify-between mb-1" style={{ fontSize: 10 }}>
            <span className="text-white/40">
              {state.status === 'complete'
                ? `Done — ${state.filesTotal} file${state.filesTotal !== 1 ? 's' : ''}`
                : state.filesTotal > 0
                  ? `${state.filesDone} / ${state.filesTotal} files`
                  : 'Scanning…'}
            </span>
            {state.filesTotal > 0 && (
              <span className="text-white/40">
                {Math.round((state.filesDone / state.filesTotal) * 100)}%
              </span>
            )}
          </div>
          <div className="h-1 rounded-full bg-white/8 overflow-hidden">
            {state.filesTotal > 0 ? (
              <div
                className="h-full rounded-full transition-all duration-500"
                style={{
                  width: `${Math.round((state.filesDone / state.filesTotal) * 100)}%`,
                  background: state.status === 'complete' ? '#4ade80' : 'var(--accent)',
                }}
              />
            ) : (
              /* indeterminate shimmer while file count not yet known */
              <div
                className="h-full w-1/3 rounded-full animate-pulse"
                style={{ background: 'var(--accent)', opacity: 0.6 }}
              />
            )}
          </div>
        </div>
      )}

      {/* Log output */}
      <div
        className="flex-1 rounded-lg border border-white/8 bg-black/30 overflow-y-auto font-mono"
        style={{ minHeight: 120, maxHeight: 200, padding: '10px 12px' }}
      >
        {state.logs.length === 0 ? (
          <p className="text-white/20" style={{ fontSize: 11 }}>
            {state.status === 'idle' ? 'Waiting to scan…' : 'No output yet.'}
          </p>
        ) : (
          state.logs.map((line, i) => (
            <p key={i} className="text-white/60 leading-relaxed" style={{ fontSize: 11 }}>
              {line}
            </p>
          ))
        )}
        <div ref={logEndRef} />
      </div>

      {state.error && (
        <p className="text-red-400 text-xs">{state.error}</p>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// ScanDialog
// ---------------------------------------------------------------------------

export default function ScanDialog({ open, onClose, onAddToLibrary }: Props) {
  const [moviePanel, setMoviePanel] = useState<PanelState>(defaultPanel)
  const [showPanel, setShowPanel] = useState<PanelState>(defaultPanel)
  const [browserOpen, setBrowserOpen] = useState(false)
  const [browserTarget, setBrowserTarget] = useState<'movie' | 'show'>('movie')
  const dialogRef = useRef<HTMLDivElement>(null)

  const activePanel = (moviePanel.status === 'scanning' || moviePanel.status === 'cancelling') ? 'movie'
    : (showPanel.status === 'scanning' || showPanel.status === 'cancelling') ? 'show'
    : null

  // Poll scan status while a panel is scanning or cancelling
  useEffect(() => {
    if (!activePanel) return

    const setPanel = activePanel === 'movie' ? setMoviePanel : setShowPanel
    let lastLogCount = 0

    const interval = setInterval(async () => {
      try {
        const status = await apiGet<ScanStatusResponse>('/api/v1/settings/library/scan/status')

        const newLogs = (status.logs ?? []).slice(lastLogCount)
        lastLogCount = status.logs?.length ?? 0
        const filesDone = status.files_done ?? 0
        const filesTotal = status.files_total ?? 0

        if (status.message === 'complete') {
          setPanel((prev) => ({
            ...prev,
            status: 'complete',
            logs: [...prev.logs, ...newLogs],
            filesDone: filesTotal,
            filesTotal,
          }))
          clearInterval(interval)
        } else if (status.message === 'cancelled') {
          clearInterval(interval)
          setMoviePanel(defaultPanel())
          setShowPanel(defaultPanel())
          onClose()
        } else if (status.message.startsWith('error')) {
          setPanel((prev) => ({
            ...prev,
            status: 'error',
            error: status.message.replace(/^error:\s*/i, ''),
            logs: [...prev.logs, ...newLogs],
            filesDone,
            filesTotal,
          }))
          clearInterval(interval)
        } else {
          setPanel((prev) => ({
            ...prev,
            logs: newLogs.length > 0 ? [...prev.logs, ...newLogs] : prev.logs,
            filesDone,
            filesTotal,
          }))
        }
      } catch {
        // silently ignore poll errors
      }
    }, 1000)

    return () => clearInterval(interval)
  }, [activePanel, onClose])

  const handleScanNow = useCallback(
    async (kind: 'movie' | 'show') => {
      const folder = kind === 'movie' ? moviePanel.folder : showPanel.folder
      if (!folder) return

      const setPanel = kind === 'movie' ? setMoviePanel : setShowPanel
      setPanel((prev) => ({ ...prev, status: 'scanning', logs: ['Starting scan…'], error: null }))

      try {
        await apiPost('/api/v1/settings/library/scan', { paths: [folder] })
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Failed to start scan'
        setPanel((prev) => ({ ...prev, status: 'error', error: msg }))
      }
    },
    [moviePanel.folder, showPanel.folder],
  )

  const openBrowser = (target: 'movie' | 'show') => {
    setBrowserTarget(target)
    setBrowserOpen(true)
  }

  const handleFolderSelect = (path: string) => {
    if (browserTarget === 'movie') {
      setMoviePanel((prev) => ({ ...defaultPanel(), folder: path }))
    } else {
      setShowPanel((prev) => ({ ...defaultPanel(), folder: path }))
    }
  }

  const canAddToLibrary = moviePanel.status === 'complete' || showPanel.status === 'complete'

  const handleReset = () => {
    setMoviePanel(defaultPanel())
    setShowPanel(defaultPanel())
  }

  const handleClose = useCallback(async () => {
    const scanningPanel =
      moviePanel.status === 'scanning' ? 'movie'
      : showPanel.status === 'scanning' ? 'show'
      : null

    if (scanningPanel) {
      // Mark panel as cancelling — keeps poll loop alive to detect 'cancelled'
      const setPanel = scanningPanel === 'movie' ? setMoviePanel : setShowPanel
      setPanel((prev) => ({ ...prev, status: 'cancelling' }))
      try {
        await apiPost('/api/v1/settings/library/scan/cancel', {})
      } catch {
        // If the cancel call fails, close immediately to avoid being stuck
        handleReset()
        onClose()
      }
      // Don't close here — poll loop closes when backend reports 'cancelled'
    } else {
      handleReset()
      onClose()
    }
  }, [moviePanel.status, showPanel.status, onClose])

  const handleAdd = () => {
    handleReset()
    onAddToLibrary()
  }

  useFocusTrap(dialogRef, open, handleClose)

  if (!open) return null

  return (
    <>
      <div
        className="fixed inset-0 z-[60] flex items-center justify-center"
        style={{ background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(8px)' }}
        onClick={moviePanel.status === 'cancelling' || showPanel.status === 'cancelling' ? undefined : handleClose}
      >
        <div
          ref={dialogRef}
          className="flex flex-col border border-white/10 rounded-2xl shadow-2xl overflow-hidden"
          style={{ width: 760, maxHeight: '85vh', background: 'rgba(14,14,20,0.98)' }}
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div
            className="flex-shrink-0 border-b border-white/8"
            style={{ padding: '18px 24px 16px' }}
          >
            <h2 className="font-bold text-white" style={{ fontSize: 17 }}>
              Scan Local Media
            </h2>
            <p className="text-white/40 text-sm" style={{ marginTop: 4 }}>
              Select folders to scan and add to your local library.
            </p>
          </div>

          {/* Two panels */}
          <div
            className="flex-1 min-h-0 overflow-y-auto flex gap-0"
            style={{ padding: '20px 24px' }}
          >
            <ScanPanel
              label="Movies"
              Icon={Film}
              state={moviePanel}
              isOtherScanning={showPanel.status === 'scanning'}
              onSelectFolder={() => openBrowser('movie')}
              onScanNow={() => handleScanNow('movie')}
            />

            {/* Vertical divider */}
            <div className="flex-shrink-0 w-px bg-white/8 mx-5 self-stretch" />

            <ScanPanel
              label="Shows"
              Icon={Tv}
              state={showPanel}
              isOtherScanning={moviePanel.status === 'scanning'}
              onSelectFolder={() => openBrowser('show')}
              onScanNow={() => handleScanNow('show')}
            />
          </div>

          {/* Footer */}
          <div
            className="flex-shrink-0 flex items-center justify-end gap-3 border-t border-white/8"
            style={{ padding: '14px 24px' }}
          >
            {(() => {
              const isCancelling = moviePanel.status === 'cancelling' || showPanel.status === 'cancelling'
              return (
                <button
                  onClick={isCancelling ? undefined : handleClose}
                  disabled={isCancelling}
                  className="px-5 py-2 rounded-lg text-sm font-medium border transition-colors cursor-pointer disabled:cursor-not-allowed disabled:opacity-60"
                  style={{
                    color: isCancelling ? 'rgba(255,255,255,0.4)' : undefined,
                    borderColor: isCancelling ? 'rgba(255,255,255,0.08)' : undefined,
                    width: '100px',
                    height: '40px'
                  }}
                  {...(!isCancelling && {
                    className: 'px-5 py-2 rounded-lg text-sm font-medium text-white/60 hover:text-white/90 border border-white/10 hover:border-white/20 transition-colors cursor-pointer',
                  })}
                >
                  {isCancelling ? 'Stopping…' : 'Cancel'}
                </button>
              )
            })()}
            <button
              onClick={handleAdd}
              disabled={!canAddToLibrary}
              className="px-5 py-2 rounded-lg text-sm font-semibold transition-all cursor-pointer disabled:opacity-35 disabled:cursor-not-allowed"
              style={{
                background: canAddToLibrary ? 'var(--accent)' : 'rgba(255,255,255,0.08)',
                color: canAddToLibrary ? '#000' : 'rgba(255,255,255,0.4)',
                border: canAddToLibrary ? 'none' : '1px solid rgba(255,255,255,0.10)',
                width: '150px',
                height: '40px'
              }}
            >
              Add to Library
            </button>
          </div>
        </div>
      </div>

      <FileBrowserModal
        open={browserOpen}
        title={`Select ${browserTarget === 'movie' ? 'Movies' : 'Shows'} Folder`}
        onSelect={handleFolderSelect}
        onClose={() => setBrowserOpen(false)}
      />
    </>
  )
}
