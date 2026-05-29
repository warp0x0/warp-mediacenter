/**
 * RatingBadges — shows TMDb and/or IMDb ratings side by side with branded icons.
 *
 * Both ratings are optional; each badge only renders when its value is present.
 * Pass `size="sm"` for the compact in-section view, `size="md"` for detail pages.
 */

interface RatingBadgesProps {
  tmdbRating?: number | null
  imdbRating?: number | null
  size?: 'sm' | 'md'
  className?: string
}

// ── Inline SVG logos ──────────────────────────────────────────────────────────

function TmdbLogo({ size }: { size: number }) {
  return (
    <svg width={size} height={size * 0.55} viewBox="0 0 185 102" fill="none" xmlns="http://www.w3.org/2000/svg" aria-label="TMDb">
      <rect width="185" height="102" rx="8" fill="#032541"/>
      <text x="12" y="72" fontFamily="Arial,sans-serif" fontWeight="800" fontSize="62" fill="url(#tg)">
        TMDb
      </text>
      <defs>
        <linearGradient id="tg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#90EE90"/>
          <stop offset="100%" stopColor="#01B4E4"/>
        </linearGradient>
      </defs>
    </svg>
  )
}

function ImdbLogo({ size }: { size: number }) {
  return (
    <svg width={size} height={size * 0.5} viewBox="0 0 120 60" fill="none" xmlns="http://www.w3.org/2000/svg" aria-label="IMDb">
      <rect width="120" height="60" rx="5" fill="#F5C518"/>
      <text x="8" y="46" fontFamily="Arial,sans-serif" fontWeight="900" fontSize="44" fill="#000000">
        IMDb
      </text>
    </svg>
  )
}

// ── Component ─────────────────────────────────────────────────────────────────

export default function RatingBadges({ tmdbRating, imdbRating, size = 'sm', className = '' }: RatingBadgesProps) {
  const logoSize  = size === 'md' ? 44 : 34
  const fontSize  = size === 'md' ? 15 : 13
  const gap       = size === 'md' ? 10 : 7

  if (!tmdbRating && !imdbRating) return null

  return (
    <span className={`flex items-center flex-wrap ${className}`} style={{ gap: size === 'md' ? 16 : 12 }}>
      {tmdbRating != null && (
        <span className="flex items-center" style={{ gap }}>
          <TmdbLogo size={logoSize} />
          <span className="font-semibold text-white" style={{ fontSize }}>
            {tmdbRating.toFixed(1)}
          </span>
        </span>
      )}
      {imdbRating != null && (
        <span className="flex items-center" style={{ gap }}>
          <ImdbLogo size={logoSize} />
          <span className="font-semibold text-white" style={{ fontSize }}>
            {imdbRating.toFixed(1)}
          </span>
        </span>
      )}
    </span>
  )
}
