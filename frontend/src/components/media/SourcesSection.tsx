import { Play, Disc3 } from 'lucide-react'
import type { SourceRow } from '@/lib/types'

interface SourcesSectionProps {
  sources: SourceRow[]
  onPlaySource: (source: SourceRow) => void
}

export default function SourcesSection({ sources, onPlaySource }: SourcesSectionProps) {
  return (
    <section className="space-y-[clamp(8px,0.83vw,16px)]">
      <h2 className="text-section font-bold text-fg-white">Sources</h2>
      {sources.length ? (
        <div className="space-y-[clamp(6px,0.52vw,12px)]">
          {sources.map((source) => (
            <div
              key={source.id}
              className="flex items-center justify-between gap-[clamp(8px,0.63vw,14px)] rounded-card border border-white/5 bg-white/[0.03] px-[clamp(10px,0.73vw,16px)] py-[clamp(8px,0.63vw,14px)]"
            >
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-[clamp(6px,0.52vw,12px)] min-w-0">
                  <Disc3 size={14} className="text-accent shrink-0" />
                  <p className="text-fg-white truncate" style={{ fontSize: 'var(--body-size)' }}>
                    {source.quality || source.source_type} {source.file_path || source.url}
                  </p>
                </div>
                <p className="text-fg-muted truncate" style={{ fontSize: 'var(--subtitle-size)' }}>
                  {source.source_type} • {source.status}
                </p>
              </div>

              <button
                onClick={() => onPlaySource(source)}
                className="flex items-center gap-[clamp(4px,0.31vw,8px)] btn-primary text-subtitle cursor-pointer"
              >
                <Play size={14} />
                Play
              </button>
            </div>
          ))}
        </div>
      ) : (
        <p className="text-fg-muted text-subtitle">No sources available yet.</p>
      )}
    </section>
  )
}
