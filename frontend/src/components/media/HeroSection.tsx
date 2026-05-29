import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Play, Loader2 } from 'lucide-react'
import { IMAGE_BASE } from '@/lib/constants'
import { useMovieDetail, useShowDetail, useImdbRating } from '@/hooks/useDetail'
import TrailerDialog from './TrailerDialog'
import RatingBadges from './RatingBadges'
import type { MediaItem } from '@/lib/types'

interface HeroSectionProps {
  item: MediaItem | null
}

export default function HeroSection({ item }: HeroSectionProps) {
  const [playing, setPlaying] = useState(false)
  const [trailerUrl, setTrailerUrl] = useState<string | null>(null)

  const tmdbId = item?.tmdb_id ?? null
  const isShow = item?.type === 'show'

  const movieDetail = useMovieDetail(isShow ? null : tmdbId)
  const showDetail = useShowDetail(isShow ? tmdbId : null)
  const detail = isShow ? showDetail.data : movieDetail.data
  const imdbRating = useImdbRating(detail?.imdb_id)

  function handlePlayTrailer() {
    const detail = isShow ? showDetail.data : movieDetail.data
    const trailers = detail?.trailers ?? []
    const trailer = trailers[0]
    if (trailer?.url) {
      setPlaying(true)
      setTrailerUrl(trailer.url)
    }
  }

  function handleCloseTrailer() {
    setTrailerUrl(null)
    setPlaying(false)
  }

  const backdropUrl = item?.backdrop_path
    ? `${IMAGE_BASE}/w1280${item.backdrop_path}`
    : null
  const title = item?.title || item?.media?.title || ''

  return (
    <AnimatePresence>
      {item && (
        <motion.section
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.4 }}
          className="relative overflow-hidden"
          style={{ minHeight: 'clamp(260px, 38vh, 520px)' }}
        >
          {backdropUrl && (
            <div className="absolute inset-0">
              <div
                className="absolute inset-0 bg-cover bg-center scale-105"
                style={{ backgroundImage: `url(${backdropUrl})` }}
              />
              <div className="absolute inset-0 bg-gradient-to-t from-bg-primary via-bg-primary/60 to-transparent" />
              <div className="absolute inset-0 bg-gradient-to-r from-bg-primary/90 via-bg-primary/40 to-transparent" />
            </div>
          )}

          {!backdropUrl && (
            <div className="absolute inset-0 bg-gradient-to-b from-bg-primary/40 to-bg-primary" />
          )}

          <div className="relative flex items-end px-[clamp(16px,2vw,40px)] pb-[clamp(16px,3vh,40px)]"
               style={{ minHeight: 'clamp(260px, 38vh, 520px)' }}>
            <div className="max-w-[clamp(400px,50vw,720px)]"
                 style={{ gap: 'clamp(10px, 1.2vh, 20px)' }}>
              <h1
                className="font-extrabold tracking-tight text-white drop-shadow-lg"
                style={{ fontSize: 'clamp(28px, 3vw, 52px)', lineHeight: 1.1 }}
              >
                {title}
              </h1>

              <div className="flex flex-wrap items-center gap-[clamp(8px,0.83vw,16px)] text-fg-white/80"
                   style={{ fontSize: 'clamp(13px, 0.9vw, 17px)', marginTop: '8px', marginBottom: '4px' }}>
                <RatingBadges
                  tmdbRating={detail?.vote_average ?? item.rating}
                  imdbRating={imdbRating.data?.rating}
                  size="sm"
                />
                {item.year && <span>{item.year}</span>}
                {item.genres?.length ? <span>{item.genres.join(' • ')}</span> : null}
              </div>

              {item.overview && (
                <p className="text-fg-white/70 leading-relaxed line-clamp-3"
                   style={{ fontSize: 'clamp(13px, 0.9vw, 16px)' }}>
                  {item.overview}
                </p>
              )}

              <div className="flex items-center gap-[clamp(8px,0.63vw,14px)]">
                <button
                  onClick={handlePlayTrailer}
                  disabled={playing}
                  className="flex items-center gap-[clamp(6px,0.42vw,10px)] btn-primary text-subtitle font-semibold cursor-pointer"
                  style={{ padding: 'clamp(10px, 0.83vw, 16px) clamp(20px, 1.67vw, 36px)' }}
                >
                  {playing ? (
                    <Loader2 size={18} className="animate-spin" />
                  ) : (
                    <Play size={18} fill="currentColor" />
                  )}
                  Play Trailer
                </button>
              </div>
            </div>
          </div>
        </motion.section>
      )}

      <TrailerDialog url={trailerUrl} onClose={handleCloseTrailer} />
    </AnimatePresence>
  )
}
