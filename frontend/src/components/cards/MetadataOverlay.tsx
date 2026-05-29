import { motion, AnimatePresence } from 'framer-motion'
import { Star, Play, Info } from 'lucide-react'
import { IMAGE_BASE } from '@/lib/constants'
import type { MediaItem } from '@/lib/types'

interface MetadataOverlayProps {
  item: MediaItem | null
  onPlay: () => void
  onMoreInfo: () => void
}

export default function MetadataOverlay({ item, onPlay, onMoreInfo }: MetadataOverlayProps) {
  return (
    <AnimatePresence>
      {item && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.3 }}
          className="relative overflow-hidden mb-[clamp(8px,0.83vw,16px)] mx-[clamp(8px,0.83vw,16px)] rounded-card"
        >
          {item.backdrop_path && (
            <div className="absolute inset-0">
              <div
                className="absolute inset-0 bg-cover bg-center"
                style={{
                  backgroundImage: `url(${IMAGE_BASE}/w1280${item.backdrop_path})`,
                }}
              />
              <div
                className="absolute inset-0"
                style={{
                  background:
                    'linear-gradient(to bottom, rgba(13,13,18,0.97), rgba(13,13,18,0.75))',
                }}
              />
            </div>
          )}

          <div
            className="relative flex items-start gap-[clamp(12px,1.25vw,24px)] p-[clamp(12px,1.25vw,24px)]"
            style={{ minHeight: 'clamp(140px, 18vh, 280px)' }}
          >
            <div className="flex-1 min-w-0">
              <h1
                className="font-extrabold text-fg-white tracking-tight mb-[clamp(4px,0.31vw,8px)]"
                style={{ fontSize: 'var(--page-title-size)' }}
              >
                {item.title || item.media?.title || item.media?.name}
              </h1>

              <div className="flex items-center gap-[clamp(8px,0.63vw,14px)] mb-[clamp(6px,0.52vw,12px)]">
                {item.year && (
                  <span className="text-fg-muted"
                        style={{ fontSize: 'var(--body-size)' }}>{item.year}</span>
                )}
                {item.rating != null && (
                  <span className="flex items-center gap-[clamp(2px,0.1vw,4px)] text-yellow-400 font-semibold"
                        style={{ fontSize: 'var(--body-size)' }}>
                    <Star size={14} className="fill-yellow-400" />
                    {item.rating.toFixed(1)}
                  </span>
                )}
              </div>

              <div className="flex items-start gap-[clamp(6px,0.52vw,12px)]">
                <button
                  onClick={onPlay}
                  className="flex items-center gap-[clamp(4px,0.31vw,8px)] btn-primary text-subtitle cursor-pointer"
                  style={{ padding: 'clamp(6px,0.42vw,10px) clamp(16px,1.25vw,28px)' }}
                >
                  <Play size={16} fill="currentColor" />
                  Play
                </button>
                <button
                  onClick={onMoreInfo}
                  className="flex items-center gap-[clamp(4px,0.31vw,8px)] btn-secondary text-subtitle cursor-pointer"
                  style={{ padding: 'clamp(6px,0.42vw,10px) clamp(16px,1.25vw,28px)' }}
                >
                  <Info size={16} />
                  More Info
                </button>
              </div>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
