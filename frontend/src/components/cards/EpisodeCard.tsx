import { Circle } from 'lucide-react'

export interface EpisodeCardData {
  id: number
  season: number
  episode: number
  name: string | null
  air_date: string | null
  has_source?: boolean
}

interface EpisodeCardProps {
  episode: EpisodeCardData
  onSelect: (episode: EpisodeCardData) => void
  onPlay: (episode: EpisodeCardData) => void
}

export default function EpisodeCard({ episode, onSelect, onPlay }: EpisodeCardProps) {
  const label = `S${String(episode.season).padStart(2, '0')}E${String(episode.episode).padStart(2, '0')}`
  const title = episode.name || `Episode ${episode.episode}`

  return (
    <div
      onClick={() => onSelect(episode)}
      onDoubleClick={() => onPlay(episode)}
      tabIndex={0}
      className="flex gap-[clamp(8px,0.63vw,14px)] rounded-card border border-white/5 bg-white/[0.02] hover:bg-white/[0.04] transition-colors cursor-pointer focus-visible:ring-2 focus-visible:ring-accent focus-visible:outline-none p-[clamp(8px,0.63vw,14px)]"
      style={{ height: 'clamp(70px, 9.26vh, 100px)' }}
    >
      <div className="flex items-center justify-center rounded-btn bg-accent-muted text-accent font-bold shrink-0"
           style={{
             width: 'clamp(60px, 5.2vw, 90px)',
             fontSize: 'clamp(11px, 0.68vw, 14px)',
           }}>
        {label}
      </div>

      <div className="flex-1 min-w-0 flex flex-col justify-center">
        <div className="flex items-center gap-[clamp(4px,0.31vw,8px)]">
          <p className="truncate text-fg-white font-medium"
             style={{ fontSize: 'var(--body-size)' }}>
            {title}
          </p>
          {episode.has_source && (
            <Circle size={8} className="text-success fill-success shrink-0" />
          )}
        </div>
        {episode.air_date && (
          <p className="text-fg-muted"
             style={{ fontSize: 'var(--subtitle-size)' }}>
            {episode.air_date}
          </p>
        )}
      </div>
    </div>
  )
}
