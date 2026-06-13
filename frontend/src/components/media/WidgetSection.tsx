import { useState, useCallback, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { Play, Loader2, ChevronLeft, ChevronRight } from 'lucide-react'
import { IMAGE_BASE } from '@/lib/constants'
import { useMovieDetail, useShowDetail, useImdbRating } from '@/hooks/useDetail'
import { useTmdbEnrichment } from '@/hooks/useTmdbEnrichment'
import TrailerDialog from './TrailerDialog'
import RatingBadges from './RatingBadges'
import type { MediaItem } from '@/lib/types'

// ── Ribbon item ───────────────────────────────────────────────────────────────

interface WidgetRibbonItemProps {
  item: MediaItem
  isSelected: boolean
  onSelect: () => void
  onNavigate: () => void
}

function WidgetRibbonItem({ item, isSelected, onSelect, onNavigate }: WidgetRibbonItemProps) {
  const { posterUrl } = useTmdbEnrichment(item, 'w300')
  return (
    <button
      onClick={onSelect}
      onDoubleClick={onNavigate}
      className={`flex-shrink-0 relative rounded-[var(--card-radius)] transition-all duration-200 cursor-pointer focus-visible:ring-2 focus-visible:ring-accent focus-visible:outline-none ${
        isSelected
          ? 'ring-2 ring-accent scale-105 shadow-[0_0_20px_rgba(13,178,226,0.3)] z-10'
          : 'hover:scale-105 hover:shadow-[0_0_16px_rgba(0,0,0,0.4)]'
      }`}
      style={{ width: 'clamp(110px, 9vw, 170px)' }}
    >
      <div className="relative overflow-hidden rounded-[var(--card-radius)] w-full">
        {posterUrl ? (
          <img
            src={posterUrl}
            alt={item.title}
            loading="lazy"
            className="w-full object-cover"
            style={{ aspectRatio: '2/3' }}
          />
        ) : (
          <div
            className="w-full bg-white/5 flex items-center justify-center text-fg-muted"
            style={{ aspectRatio: '2/3', fontSize: 'clamp(9px,0.56vw,11px)' }}
          >
            No Poster
          </div>
        )}

        {typeof item.extra?.progress === 'number' && (item.extra.progress as number) > 0 && (
          <div className="absolute left-0 right-0 h-[6px] bg-white/15" style={{ bottom: '1.5px' }}>
            <div
              className="h-full bg-amber-400 rounded-r-full"
              style={{ width: `${Math.min(100, item.extra.progress as number)}%` }}
            />
          </div>
        )}
      </div>
    </button>
  )
}

interface WidgetSectionProps {
  title: string
  items: MediaItem[]
  isLoading?: boolean
  mediaType?: 'movie' | 'show'
  provider?: string
  category?: string
}

export default function WidgetSection({ title, items, isLoading, mediaType = 'movie', provider, category }: WidgetSectionProps) {
  const navigate = useNavigate()
  const [selectedIdx, setSelectedIdx] = useState(0)
  const [playing, setPlaying] = useState(false)
  const [trailerUrl, setTrailerUrl] = useState<string | null>(null)
  const ribbonRef = useRef<HTMLDivElement>(null)
  const synopsisRef = useRef<HTMLParagraphElement>(null)
  const [synopsisClamped, setSynopsisClamped] = useState(true)


  const selected = items[selectedIdx] ?? null
  const tmdbId = selected?.tmdb_id ?? null
  const movieDetail = useMovieDetail(mediaType === 'movie' ? tmdbId : null)
  const showDetail = useShowDetail(mediaType === 'show' ? tmdbId : null)
  const detail = mediaType === 'movie' ? movieDetail.data : showDetail.data
  const imdbRating = useImdbRating(detail?.imdb_id)

  const handleSelect = useCallback((idx: number) => {
    setSelectedIdx(idx)
  }, [])

  const handleNavigate = useCallback((item: MediaItem) => {
    navigate(`/detail/${item.tmdb_id || item.id}`, { state: { item } })
  }, [navigate])

  const scrollRibbon = (direction: 'left' | 'right') => {
    const el = ribbonRef.current
    if (!el) return
    const amount = direction === 'left' ? -400 : 400
    el.scrollBy({ left: amount, behavior: 'smooth' })
  }

  function handlePlayTrailer() {
    const trailer = detail?.trailers?.[0]
    if (trailer?.url) {
      setPlaying(true)
      setTrailerUrl(trailer.url)
    }
  }

  function handleCloseTrailer() {
    setTrailerUrl(null)
    setPlaying(false)
  }

  useEffect(() => {
    setSynopsisClamped(true)
    const el = synopsisRef.current
    if (!el || !selected?.overview) return
    el.scrollTop = 0

    const checkOverflow = () => {
      if (el.scrollHeight > el.clientHeight) {
        const timer = setTimeout(() => {
          setSynopsisClamped(false)
          let pos = 0
          const maxScroll = el.scrollHeight - el.clientHeight
          const step = () => {
            pos += 0.5
            if (pos >= maxScroll) {
              el.scrollTop = maxScroll
              return
            }
            el.scrollTop = pos
            requestAnimationFrame(step)
          }
          step()
        }, 3000)
        return () => clearTimeout(timer)
      }
    }

    const t = setTimeout(checkOverflow, 200)
    return () => clearTimeout(t)
  }, [selected?.overview])

  if (isLoading) {
    return (
      <section className="min-h-full w-full flex items-center justify-center bg-bg-primary snap-start">
        <div className="animate-pulse space-y-[clamp(12px,1.25vw,24px)]">
          <div className="w-[clamp(240px,20vw,400px)] h-[clamp(40px,5vh,60px)] bg-white/5 rounded-card" />
          <div className="w-[clamp(300px,30vw,600px)] h-[clamp(16px,2vh,24px)] bg-white/5 rounded-pill" />
        </div>
      </section>
    )
  }

  if (!items.length) {
    return (
      <section className="min-h-full w-full flex items-center justify-center bg-bg-primary snap-start">
        <p className="text-fg-muted" style={{ fontSize: 'var(--body-size)' }}>No items available</p>
      </section>
    )
  }

  const backdropUrl = selected?.backdrop_path
    ? `${IMAGE_BASE}/w1280${selected.backdrop_path}`
    : null

  return (
    <section className="min-h-full w-full relative overflow-hidden flex flex-col snap-start" style={{ paddingTop: 'var(--tabbar-height)' }}>
      <AnimatePresence mode="wait">
        <motion.div
          key={backdropUrl || 'no-backdrop'}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.5, ease: 'easeInOut' }}
          className="absolute inset-0"
        >
          {backdropUrl ? (
            <div
              className="absolute inset-0"
              style={{
                backgroundImage: `url(${backdropUrl})`,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
                backgroundRepeat: 'no-repeat',
              }}
            />
          ) : (
            <div className="absolute inset-0 bg-bg-primary" />
          )}
        </motion.div>
      </AnimatePresence>

      <div
        className="absolute bottom-0 left-0 right-0 pointer-events-none"
        style={{
          height: '65vh',
          background: 'linear-gradient(to top, rgba(0,0,0,0.95) 0%, rgba(0,0,0,0.85) 25%, rgba(0,0,0,0.6) 50%, rgba(0,0,0,0.2) 75%, transparent 100%)',
        }}
      />

      <div className="fixed top-0 left-0 z-40 pointer-events-none"
           style={{
             width: 'clamp(27px, 2.7vw, 54px)',
             height: '100vh',
             background: 'linear-gradient(to right, rgba(0,0,0,0.75) 0%, rgba(0,0,0,0.45) 20%, rgba(0,0,0,0.18) 50%, rgba(0,0,0,0.04) 80%, transparent 100%)',
           }} />
      <div className="fixed top-0 right-0 z-40 pointer-events-none"
           style={{
             width: 'clamp(27px, 2.7vw, 54px)',
             height: '100vh',
             background: 'linear-gradient(to left, rgba(0,0,0,0.75) 0%, rgba(0,0,0,0.45) 20%, rgba(0,0,0,0.18) 50%, rgba(0,0,0,0.04) 80%, transparent 100%)',
            }} />

      <div
        className="absolute left-0 top-0 bottom-0 z-10 pointer-events-none"
        style={{
          width: '60%',
          background: 'linear-gradient(to right, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.5) 40%, transparent 100%)',
          backdropFilter: 'blur(3px)',
          WebkitBackdropFilter: 'blur(3px)',
        }}
      />

      <div className="flex-1 min-h-0" />

      <div className="relative w-full z-20"
      style={{ paddingLeft: 'clamp(45px, 4.5vw, 90px)', paddingRight: 'clamp(45px, 4.5vw, 90px)', paddingBottom: 'clamp(20px, 2.5vh, 36px)' }}>

        <div className="max-w-[clamp(320px,42vw,680px)]"
             style={{ marginBottom: '6px' }}>
            <h1
              className="font-extrabold tracking-tight text-white"
              style={{
                fontSize: 'clamp(32px, 3.5vw, 56px)',
                lineHeight: 1.1,
                textShadow: '2px 4px 12px rgba(0,0,0,0.8)',
                marginBottom: 'clamp(22px, 2.8vh, 30px)',
              }}
            >
              {selected?.title || selected?.media?.title || ''}
            </h1>

            <p
              ref={synopsisRef}
              className={`font-normal leading-relaxed text-white/90 ${synopsisClamped ? 'line-clamp-3 overflow-hidden' : 'overflow-y-auto scrollbar-hidden'}`}
              style={{
                fontSize: 'clamp(16px, 1.2vw, 22px)',
                lineHeight: 1.6,
                maxWidth: 700,
                maxHeight: synopsisClamped ? undefined : 'calc(clamp(16px, 1.2vw, 22px) * 1.6 * 3)',
                textShadow: '1px 2px 8px rgba(0,0,0,0.9)',
                marginBottom: 'clamp(22px, 2.8vh, 30px)',
              }}
            >
              {selected?.overview || 'No synopsis available.'}
            </p>

            <div className="flex items-center flex-wrap gap-[clamp(12px,1.2vw,20px)]"
                 style={{ marginBottom: 'clamp(22px, 2.8vh, 30px)' }}>
              <RatingBadges
                tmdbRating={detail?.vote_average ?? selected?.rating}
                imdbRating={imdbRating.data?.rating}
                size="sm"
              />
              {selected?.year && (
                <span className="text-white/85 font-medium" style={{ fontSize: 'clamp(14px, 0.9vw, 18px)' }}>{selected.year}</span>
              )}
              {detail && ('runtime_minutes' in detail ? detail.runtime_minutes : null) && (
                <span className="text-white/60" style={{ fontSize: 'clamp(14px, 0.9vw, 18px)' }}>{(detail as { runtime_minutes: number }).runtime_minutes} min</span>
              )}
            </div>

            <div className="flex items-center gap-[clamp(12px,1vw,20px)]">
            <button
              onClick={handlePlayTrailer}
              disabled={playing}
              className="flex items-center gap-[clamp(6px,0.42vw,10px)] btn-primary font-semibold cursor-pointer transition-all duration-200 hover:scale-105"
              style={{
                padding: 'clamp(10px, 0.8vw, 18px) clamp(20px, 2vw, 42px)',
                fontSize: 'clamp(17px, 1.2vw, 22px)',
                marginBottom: '35px',
              }}
            >
              {playing ? (
                <Loader2 size={20} className="animate-spin" />
              ) : (
                <Play size={20} fill="currentColor" />
              )}
              Play Trailer
            </button>

            <button
              onClick={() => selected && handleNavigate(selected)}
              className="flex items-center gap-[clamp(6px,0.42vw,10px)] font-semibold cursor-pointer transition-all duration-200 hover:scale-105"
              style={{
                padding: 'clamp(10px, 0.8vw, 18px) clamp(20px, 2vw, 42px)',
                fontSize: 'clamp(17px, 1.2vw, 22px)',
                marginBottom: '35px',
                background: 'rgba(51, 50, 50, 0.79)',
                border: '1px solid rgb(2, 181, 252)',
                borderRadius: '8px',
                color: '#fff',
              }}
            >
              {selected?.extra?.resume_available
                ? (selected.type === 'show' && selected.extra?.resume_season != null
                    ? `Resume S${String(selected.extra.resume_season).padStart(2, '0')}E${String(selected.extra.resume_episode ?? 1).padStart(2, '0')}`
                    : 'Resume')
                : 'More Info'}
            </button>
            </div>
          </div>

        <div className="flex items-center justify-between"
             style={{
               textShadow: '1px 1px 4px rgba(0,0,0,0.8)',
               marginBottom: 'clamp(6px, 1.0vh, 15px)',
              //  marginTop: 'clamp(16px, 1.0vh, 15px)',
             }}>
            <p
              className="uppercase tracking-[0.15em] text-white font-bold"
              style={{ 
                fontSize: 'clamp(12px, 0.8vw, 14px)', 
                // marginTop: '10px' 
              }}
            >
              {title}
            </p>
            {!(category === 'continue_watching' && items.length <= 10) && (
              <button
                onClick={() =>
                  provider && category
                    ? navigate(
                        `/catalog/${provider}/${category}?type=${mediaType}&title=${encodeURIComponent(title)}`,
                      )
                    : navigate(`/search?q=${encodeURIComponent(title)}`)
                }
                className="uppercase tracking-[0.15em] text-white font-bold cursor-pointer hover:text-accent transition-colors"
                style={{ fontSize: 'clamp(12px, 0.8vw, 14px)' }}
              >
                See More &rarr;
              </button>
            )}
          </div>

        <div className="relative group">
          <button
            onClick={() => scrollRibbon('left')}
            className="absolute top-1/2 -translate-y-1/2 z-20 bg-black/50 backdrop-blur-sm hover:bg-black/70 text-white rounded-full p-[clamp(6px,0.42vw,10px)] opacity-0 group-hover:opacity-100 transition-opacity duration-200 cursor-pointer shadow-[0_2px_8px_rgba(0,0,0,0.4)]"
            style={{ left: 'clamp(4px, 0.3vw, 8px)' }}
          >
            <ChevronLeft size={50} />
          </button>
          <button
            onClick={() => scrollRibbon('right')}
            className="absolute top-1/2 -translate-y-1/2 z-20 bg-black/50 backdrop-blur-sm hover:bg-black/70 text-white rounded-full p-[clamp(6px,0.42vw,10px)] opacity-0 group-hover:opacity-100 transition-opacity duration-200 cursor-pointer shadow-[0_2px_8px_rgba(0,0,0,0.4)]"
            style={{ right: 'clamp(4px, 0.3vw, 8px)' }}
          >
            <ChevronRight size={50} />
          </button>

          <div
            ref={ribbonRef}
            className="flex gap-[var(--card-gap)] overflow-hidden scrollbar-hidden"
            style={{ paddingTop: '8px', paddingBottom: '8px', paddingLeft: '4px' }}
          >
          {items.map((item, idx) => (
            <WidgetRibbonItem
              key={item.id}
              item={item}
              isSelected={idx === selectedIdx}
              onSelect={() => handleSelect(idx)}
              onNavigate={() => handleNavigate(item)}
            />
          ))}
          </div>
        </div>
      </div>

      <TrailerDialog url={trailerUrl} onClose={handleCloseTrailer} />
    </section>
  )
}
