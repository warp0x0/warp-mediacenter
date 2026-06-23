import { useState, useEffect, useRef } from 'react'

import { ChevronRight, Folder, FolderOpen, X, Check, ChevronLeft } from 'lucide-react'

import { apiGet } from '@/lib/api'
import { useFocusTrap } from '@/hooks/useFocusTrap'
import type { FileBrowseResponse } from '@/lib/types'

interface Props {
  open: boolean
  title?: string
  onSelect: (path: string) => void
  onClose: () => void
}

export default function FileBrowserModal({ open, title = 'Select Folder', onSelect, onClose }: Props) {
  const [currentPath, setCurrentPath] = useState('')
  const [browse, setBrowse] = useState<FileBrowseResponse | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const dialogRef = useRef<HTMLDivElement>(null)

  useFocusTrap(dialogRef, open, onClose)

  const navigate = async (path: string) => {
    setIsLoading(true)
    try {
      const data = await apiGet<FileBrowseResponse>('/api/v1/files/browse', path ? { path } : {})
      setBrowse(data)
      setCurrentPath(data.path)
    } catch {
      // keep current view on error
    } finally {
      setIsLoading(false)
    }
  }

  // Load home dir when opened
  useEffect(() => {
    if (open) navigate('')
  }, [open]) // eslint-disable-line react-hooks/exhaustive-deps

  if (!open) return null

  const dirs = browse?.entries.filter((e) => e.is_dir) ?? []

  // Build breadcrumbs from current path
  const pathParts = currentPath ? currentPath.replace(/\\/g, '/').split('/').filter(Boolean) : []
  const breadcrumbs = pathParts.map((part, i) => ({
    label: part || '/',
    path: '/' + pathParts.slice(0, i + 1).join('/'),
  }))

  return (
    <div
      className="fixed inset-0 z-[70] flex items-center justify-center"
      style={{ background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(8px)' }}
      onClick={onClose}
    >
      <div
        ref={dialogRef}
        className="flex flex-col border border-white/10 rounded-2xl shadow-2xl overflow-hidden"
        style={{ width: 560, maxHeight: '70vh', background: 'rgba(14,14,20,0.98)' }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          className="flex-shrink-0 flex items-center justify-between border-b border-white/8"
          style={{ padding: '16px 20px' }}
        >
          <h2 className="text-white font-bold" style={{ fontSize: 16 }}>
            {title}
          </h2>
          <button
            onClick={onClose}
            className="text-white/40 hover:text-white/80 transition-colors cursor-pointer"
          >
            <X size={18} />
          </button>
        </div>

        {/* Breadcrumb */}
        <div
          className="flex-shrink-0 flex items-center gap-1 overflow-x-auto scrollbar-hidden border-b border-white/8"
          style={{ padding: '8px 20px', minHeight: 36 }}
        >
          <button
            onClick={() => navigate('')}
            className="text-white/50 hover:text-white/90 transition-colors text-xs font-medium cursor-pointer flex-shrink-0"
          >
            ~
          </button>
          {breadcrumbs.map((crumb, i) => (
            <span key={crumb.path} className="flex items-center gap-1 flex-shrink-0">
              <ChevronRight size={12} className="text-white/30" />
              <button
                onClick={() => navigate(crumb.path)}
                className={`text-xs font-medium transition-colors cursor-pointer ${
                  i === breadcrumbs.length - 1
                    ? 'text-white/90'
                    : 'text-white/50 hover:text-white/80'
                }`}
              >
                {crumb.label}
              </button>
            </span>
          ))}
        </div>

        {/* Directory listing */}
        <div className="flex-1 min-h-0 overflow-y-auto" style={{ padding: '8px 0' }}>
          {/* Up one level */}
          {browse?.parent && (
            <button
              onClick={() => navigate(browse.parent!)}
              className="w-full flex items-center gap-3 px-5 py-2.5 text-white/50 hover:text-white/80 hover:bg-white/5 transition-colors text-sm cursor-pointer"
            >
              <ChevronLeft size={15} />
              <span>..</span>
            </button>
          )}

          {isLoading && (
            <div className="flex items-center justify-center py-8">
              <div className="w-5 h-5 border-2 border-accent border-t-transparent rounded-full animate-spin" />
            </div>
          )}

          {!isLoading && dirs.length === 0 && (
            <p className="text-white/30 text-sm text-center py-8">No folders here</p>
          )}

          {!isLoading &&
            dirs.map((entry) => (
              <button
                key={entry.path}
                onClick={() => navigate(entry.path)}
                className="w-full flex items-center gap-3 px-5 py-2.5 hover:bg-white/5 transition-colors text-sm cursor-pointer group"
              >
                <FolderOpen
                  size={16}
                  className="text-amber-400/70 group-hover:text-amber-400 transition-colors flex-shrink-0"
                />
                <span className="text-white/80 group-hover:text-white transition-colors truncate text-left">
                  {entry.name}
                </span>
                <ChevronRight size={13} className="text-white/20 group-hover:text-white/50 transition-colors ml-auto flex-shrink-0" />
              </button>
            ))}
        </div>

        {/* Footer */}
        <div
          className="flex-shrink-0 flex items-center justify-between gap-3 border-t border-white/8"
          style={{ padding: '14px 20px' }}
        >
          <div className="flex items-center gap-2 min-w-0">
            <Folder size={14} className="text-amber-400/60 flex-shrink-0" />
            <span className="text-white/50 text-xs truncate">{currentPath || '~'}</span>
          </div>
          <div className="flex gap-3 flex-shrink-0">
            <button
              onClick={onClose}
              className="rounded-xl text-sm font-semibold text-white/60 hover:text-white hover:bg-white/8 border border-white/12 hover:border-white/25 transition-all duration-150 cursor-pointer"
              style={{ minWidth: 110, height: 42, padding: '0 22px' }}
            >
              Cancel
            </button>
            <button
              onClick={() => { onSelect(currentPath); onClose() }}
              disabled={!currentPath}
              className="flex items-center justify-center gap-2 rounded-xl text-sm font-semibold transition-all duration-150 cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed hover:brightness-110"
              style={{ minWidth: 110, height: 42, padding: '0 22px', background: 'var(--accent)', color: '#000' }}
            >
              <Check size={15} />
              Select Folder
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
