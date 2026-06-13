import { motion } from 'framer-motion'
import { Star } from 'lucide-react'
import { useTmdbEnrichment } from '@/hooks/useTmdbEnrichment'
import CollectionButtons from './CollectionButtons'
import type { MediaItem } from '@/lib/types'

interface PosterCardProps {
  item: MediaItem
  onSelect: (item: MediaItem) => void
  onNavigate: (item: MediaItem) => void
}

export default function PosterCard({ item, onSelect, onNavigate }: PosterCardProps) {
  const title = item.title || item.media?.title || item.media?.name || 'Unknown'
  const { posterUrl, rating } = useTmdbEnrichment(item)
  const year = item.year

  return (
    <motion.div
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.98 }}
      transition={{ duration: 0.15, ease: 'easeOut' }}
      onClick={() => onSelect(item)}
      onDoubleClick={() => onNavigate(item)}
      tabIndex={0}
      onFocus={(e) => { if (e.target === e.currentTarget) onSelect(item) }}
      className="flex-shrink-0 flex flex-col gap-[clamp(4px,0.31vw,8px)] cursor-pointer rounded-[var(--card-radius)] focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-bg-primary focus-visible:outline-none group"
      style={{ width: 'var(--poster-width)' }}
    >
      <div
        className="relative bg-bg-card overflow-hidden rounded-[var(--card-radius)]"
        style={{ height: 'var(--poster-height)' }}
      >
        {posterUrl ? (
          <img
            src={posterUrl}
            alt={title}
            loading="lazy"
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-white/5 text-fg-muted text-subtitle">
            No Poster
          </div>
        )}

        <CollectionButtons item={item} />

        {rating != null && (
          <div
            className="absolute top-[clamp(4px,0.31vw,8px)] right-[clamp(4px,0.31vw,8px)] flex items-center justify-center gap-[clamp(2px,0.1vw,4px)] bg-black/70 backdrop-blur-sm rounded-pill px-[clamp(4px,0.31vw,8px)] py-[clamp(1px,0.1vw,3px)]"
            style={{ fontSize: 'clamp(11px, 0.68vw, 14px)', width: '50px', height: '25px' }}
          >
            <Star size={11} className="text-yellow-400 fill-yellow-400" />
            <span className="text-white font-semibold">{rating.toFixed(1)}</span>
          </div>
        )}
      </div>

      <div className="px-[clamp(2px,0.16vw,4px)] pb-[clamp(2px,0.2vw,4px)]">
        <p
          className="truncate text-fg-white font-medium leading-snug"
          style={{ fontSize: 'clamp(12px, 0.73vw, 15px)' }}
        >
          {title}
        </p>
        {year && (
          <p
            className="text-fg-muted leading-snug"
            style={{ fontSize: 'clamp(10px, 0.63vw, 13px)' }}
          >
            {year}
          </p>
        )}
      </div>
    </motion.div>
  )
}
