import type { CastMember } from '@/lib/types'

interface CastSectionProps {
  cast: CastMember[]
}

export default function CastSection({ cast }: CastSectionProps) {
  if (!cast.length) {
    return (
      <section className="space-y-[clamp(8px,0.83vw,16px)]">
        <h2 className="text-section font-bold text-fg-white">Cast</h2>
        <p className="text-fg-muted text-subtitle">Cast data is not available yet.</p>
      </section>
    )
  }

  return (
    <section className="space-y-[clamp(8px,0.83vw,16px)]">
      <h2 className="text-section font-bold text-fg-white">Cast</h2>
      <div className="flex gap-[var(--card-gap)] overflow-x-auto scrollbar-hidden pb-[clamp(4px,0.31vw,8px)]">
        {cast.map((person, idx) => (
          <div
            key={`${person.name}-${idx}`}
            className="flex-shrink-0 w-[clamp(120px,8.5vw,160px)] rounded-card border border-white/5 bg-white/[0.03] p-[clamp(8px,0.63vw,14px)]"
          >
            <div className="aspect-[2/3] rounded-btn bg-white/5 mb-[clamp(6px,0.52vw,12px)] overflow-hidden flex items-center justify-center">
              {person.profile_path ? (
                <img
                  src={`https://image.tmdb.org/t/p/w300${person.profile_path}`}
                  alt={person.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <span className="text-fg-muted text-subtitle text-center px-[clamp(6px,0.52vw,12px)]">No Photo</span>
              )}
            </div>
            <p className="text-fg-white font-medium truncate" style={{ fontSize: 'var(--body-size)' }}>
              {person.name}
            </p>
            {person.character && (
              <p className="text-fg-muted truncate" style={{ fontSize: 'var(--subtitle-size)' }}>
                {person.character}
              </p>
            )}
          </div>
        ))}
      </div>
    </section>
  )
}
