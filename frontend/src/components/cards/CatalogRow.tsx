import type { MediaItem } from '@/lib/types'
import PosterCard from './PosterCard'

interface CatalogRowProps {
  title: string
  items: MediaItem[]
  isLoading?: boolean
  onCardSelect: (item: MediaItem) => void
  onCardNavigate: (item: MediaItem) => void
}

export default function CatalogRow({
  title,
  items,
  isLoading,
  onCardSelect,
  onCardNavigate,
}: CatalogRowProps) {
  if (isLoading) {
    return (
      <div className="mb-[clamp(12px,1.25vw,24px)]">
        <div className="flex items-center justify-between px-[clamp(8px,0.83vw,16px)] mb-[clamp(6px,0.52vw,12px)]">
          <h2
            className="font-bold text-fg-white"
            style={{ fontSize: 'var(--section-title-size)' }}
          >
            {title}
          </h2>
        </div>
        <div className="flex gap-[var(--card-gap)] px-[clamp(8px,0.83vw,16px)] overflow-hidden">
          {Array.from({ length: 8 }).map((_, i) => (
            <div
              key={i}
              className="flex-shrink-0 animate-pulse"
              style={{ width: 'var(--poster-width)' }}
            >
              <div
                className="bg-white/5 rounded-[var(--card-radius)]"
                style={{ height: 'var(--poster-height)' }}
              />
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (!items.length) {
    return (
      <div className="mb-[clamp(12px,1.25vw,24px)]">
        <h2
          className="font-bold text-fg-white px-[clamp(8px,0.83vw,16px)] mb-[clamp(6px,0.52vw,12px)]"
          style={{ fontSize: 'var(--section-title-size)' }}
        >
          {title}
        </h2>
        <p className="text-fg-muted text-body px-[clamp(8px,0.83vw,16px)]">No items available</p>
      </div>
    )
  }

  return (
    <div className="mb-[clamp(12px,1.25vw,24px)]">
      <div className="flex items-center justify-between px-[clamp(8px,0.83vw,16px)] mb-[clamp(6px,0.52vw,12px)]">
        <h2
          className="font-bold text-fg-white"
          style={{ fontSize: 'var(--section-title-size)' }}
        >
          {title}
        </h2>
        <button className="text-subtitle text-accent hover:text-accent-hover font-medium transition-colors cursor-pointer">
          See All
        </button>
      </div>

      <div className="flex gap-[var(--card-gap)] px-[clamp(8px,0.83vw,16px)] overflow-x-auto scrollbar-hidden pb-[clamp(4px,0.31vw,8px)]">
        {items.map((item) => (
          <PosterCard
            key={item.id}
            item={item}
            onSelect={onCardSelect}
            onNavigate={onCardNavigate}
          />
        ))}
      </div>
    </div>
  )
}
