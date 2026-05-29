import EpisodeCard, { type EpisodeCardData } from '@/components/cards/EpisodeCard'

interface EpisodeGridProps {
  episodes: EpisodeCardData[]
  allSeasons: number[]
  selectedSeason: number
  onSeasonChange: (season: number) => void
  onEpisodeSelect: (episode: EpisodeCardData) => void
  onEpisodePlay: (episode: EpisodeCardData) => void
  onBack: () => void
}

export default function EpisodeGrid({
  episodes,
  allSeasons,
  selectedSeason,
  onSeasonChange,
  onEpisodeSelect,
  onEpisodePlay,
  onBack,
}: EpisodeGridProps) {
  return (
    <div>
      <div className="flex items-center justify-between px-[clamp(8px,0.83vw,16px)] pt-[clamp(8px,0.83vw,16px)] mb-[clamp(8px,0.83vw,16px)]">
        <button
          onClick={onBack}
          className="flex items-center gap-[clamp(4px,0.31vw,8px)] text-subtitle text-accent hover:text-accent-hover font-medium transition-colors cursor-pointer"
        >
          &larr; Back
        </button>
      </div>

      {allSeasons.length > 1 && (
        <div className="px-[clamp(8px,0.83vw,16px)] mb-[clamp(8px,0.83vw,16px)]">
          <label className="text-fg-muted text-subtitle mr-[clamp(4px,0.31vw,8px)]">
            Season:
          </label>
          <select
            value={selectedSeason}
            onChange={(e) => onSeasonChange(Number(e.target.value))}
            className="bg-white/5 text-fg-primary border border-white/10 rounded-input px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] text-body cursor-pointer focus:outline-none focus:border-accent"
          >
            {allSeasons.map((s) => (
              <option key={s} value={s}>
                {s === 0 ? 'Specials' : `Season ${s}`}
              </option>
            ))}
          </select>
        </div>
      )}

      {!episodes.length && (
        <div className="flex flex-col items-center justify-center py-[clamp(40px,8vh,80px)] text-fg-muted">
          <p style={{ fontSize: 'var(--body-size)' }}>No episodes available for this season.</p>
        </div>
      )}

      <div className="grid gap-[clamp(8px,0.63vw,14px)] px-[clamp(8px,0.83vw,16px)] pb-[clamp(16px,2vh,32px)]"
           style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(clamp(240px, 16vw, 320px), 1fr))' }}>
        {episodes.map((ep) => (
          <EpisodeCard
            key={ep.id}
            episode={ep}
            onSelect={onEpisodeSelect}
            onPlay={onEpisodePlay}
          />
        ))}
      </div>
    </div>
  )
}
