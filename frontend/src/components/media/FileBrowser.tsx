import { FolderOpen, File } from 'lucide-react'

interface FileBrowserProps {
  path: string
}

export default function FileBrowser({ path }: FileBrowserProps) {
  const segments = path.split('/').filter(Boolean)

  return (
    <div className="rounded-card border border-white/5 bg-white/[0.03] overflow-hidden">
      <div className="flex items-center gap-[clamp(6px,0.52vw,12px)] px-[clamp(8px,0.63vw,14px)] py-[clamp(6px,0.52vw,12px)] border-b border-white/5 text-fg-muted"
           style={{ fontSize: 'var(--subtitle-size)' }}>
        <FolderOpen size={14} />
        <span className="truncate">{segments.slice(-2).join('/') || '/'}</span>
      </div>
      <div className="p-[clamp(8px,0.63vw,14px)]">
        <div className="flex items-center gap-[clamp(6px,0.52vw,12px)] text-fg-muted"
             style={{ fontSize: 'var(--subtitle-size)' }}>
          <File size={14} />
          Ready to browse {path}
        </div>
      </div>
    </div>
  )
}
