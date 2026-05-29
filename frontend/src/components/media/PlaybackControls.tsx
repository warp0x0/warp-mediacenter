import { Pause, Play, Square, Subtitles, Volume2 } from 'lucide-react'
import type { PlayerStatus } from '@/lib/types'

interface PlaybackControlsProps {
  status: PlayerStatus | undefined
  onTogglePlayPause: () => void
  onStop: () => void
  onSeek: (positionMs: number) => void
  onVolume: (volume: number) => void
  onOpenSubtitles: () => void
}

function formatMs(ms?: number) {
  const value = Math.max(0, ms || 0)
  const total = Math.floor(value / 1000)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = total % 60
  return h > 0 ? `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}` : `${m}:${String(s).padStart(2, '0')}`
}

export default function PlaybackControls({
  status,
  onTogglePlayPause,
  onStop,
  onSeek,
  onVolume,
  onOpenSubtitles,
}: PlaybackControlsProps) {
  const duration = status?.duration_ms || 0
  const position = status?.position_ms || 0
  const volume = status?.volume ?? 100
  const progress = duration > 0 ? Math.min(100, Math.max(0, (position / duration) * 100)) : 0

  return (
    <div className="rounded-card border border-white/5 bg-bg-panel p-[clamp(12px,1.25vw,24px)] space-y-[clamp(10px,0.73vw,16px)]">
      <div className="flex items-center justify-between gap-[clamp(8px,0.63vw,14px)]">
        <div className="min-w-0">
          <p className="text-fg-white font-medium truncate" style={{ fontSize: 'var(--body-size)' }}>
            {status?.title || 'Playback'}
          </p>
          <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>
            {formatMs(position)} / {formatMs(duration)}
          </p>
        </div>

        <div className="flex items-center gap-[clamp(4px,0.31vw,8px)]">
          <button onClick={onTogglePlayPause} className="btn-primary cursor-pointer">
            {status?.playing ? <Pause size={16} /> : <Play size={16} />}
          </button>
          <button onClick={onStop} className="btn-secondary cursor-pointer">
            <Square size={16} />
          </button>
          <button onClick={onOpenSubtitles} className="btn-secondary cursor-pointer">
            <Subtitles size={16} />
          </button>
        </div>
      </div>

      <div className="space-y-[clamp(6px,0.52vw,12px)]">
        <input
          type="range"
          min={0}
          max={100}
          value={progress}
          onChange={(e) => {
            const pct = Number(e.target.value)
            onSeek(Math.round((pct / 100) * duration))
          }}
          className="w-full accent-[var(--accent)]"
        />

        <div className="flex items-center gap-[clamp(8px,0.63vw,14px)]">
          <Volume2 size={16} className="text-fg-muted shrink-0" />
          <input
            type="range"
            min={0}
            max={100}
            value={volume}
            onChange={(e) => onVolume(Number(e.target.value))}
            className="w-full accent-[var(--accent)]"
          />
        </div>
      </div>
    </div>
  )
}
