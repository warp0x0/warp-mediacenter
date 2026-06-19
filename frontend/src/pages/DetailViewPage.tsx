import { useEffect, useMemo, useRef, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Play, Star, Plus, Share2, Heart, Loader2, Tags, CheckCircle2, HardDrive, ChevronLeft, ChevronRight } from 'lucide-react'
import { useBackdrop } from '@/contexts/BackdropContext'
import { useTitleDetail, useTitleSources } from '@/hooks/useLibrary'
import { useMovieDetail, useShowDetail, useShowSeasons, useImdbRating, useShowProgress } from '@/hooks/useDetail'
import RatingBadges from '@/components/media/RatingBadges'
import TorrentDialog from '@/components/media/TorrentDialog'
import TrailerDialog from '@/components/media/TrailerDialog'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { useApi } from '@/hooks/useApi'
import { useIsLiked, useIsWishlisted } from '@/hooks/useCollections'
import { playMedia } from '@/hooks/usePlayer'
import { isTauriRuntime, openPlayerWindow } from '@/lib/tauri'
import { IMAGE_BASE } from '@/lib/constants'
import { BASE_URL } from '@/lib/api'
import type { CastMember, CollectionItemPayload, EpisodeDetail, MediaItem, SourceRow, WatchProvidersResponse, SeasonDetail } from '@/lib/types'

type DetailLocationState = { item?: MediaItem }

export default function DetailViewPage() {
  const { mediaId } = useParams()
  const location = useLocation()
  const navigate = useNavigate()
  const { setBackdrop, clearBackdrop } = useBackdrop()
  const [torrentOpen, setTorrentOpen] = useState(false)
  const [torrentSeason, setTorrentSeason] = useState<number | null>(null)
  const [torrentEpisode, setTorrentEpisode] = useState<number | null>(null)
  const [trailerPlaying, setTrailerPlaying] = useState(false)
  const [trailerModalUrl, setTrailerModalUrl] = useState<string | null>(null)
  // Resume modal state
  const [resumeModalOpen, setResumeModalOpen] = useState(false)
  const [resumePercent, setResumePercent] = useState<number | null>(null)
  const state = location.state as DetailLocationState | null

  const media = state?.item ?? null
  const titleId = media?.tmdb_id || mediaId || null
  const detailQuery = useTitleDetail(titleId)
  const sourcesQuery = useTitleSources(titleId)
  const detail = detailQuery.data ?? null
  const mediaKind = ((media?.type || detail?.type) === 'show' ? 'tv' : 'movie') as 'movie' | 'tv'
  const isShow = mediaKind === 'tv'
  const tmdbId = (media?.tmdb_id ?? detail?.tmdb_id ?? null)

  const { isLiked, toggle: toggleLiked } = useIsLiked(tmdbId)
  const { isWishlisted, toggle: toggleWishlisted } = useIsWishlisted(tmdbId)

  const movieDetail = useMovieDetail(isShow ? null : tmdbId)
  const showDetail = useShowDetail(isShow ? tmdbId : null)
  const richDetail = isShow ? showDetail.data : movieDetail.data
  const imdbRating = useImdbRating(richDetail?.imdb_id)
  const seasonsQuery = useShowSeasons(isShow ? tmdbId : null)
  const showProgressQuery = useShowProgress(isShow ? tmdbId : null)
  const [selectedSeasonIdx, setSelectedSeasonIdx] = useState(0)
  const seasonScrollRef = useRef<HTMLDivElement>(null)

  // ── Movie resume / progress — from navigation state (Continue Watching) ────
  const movieResumeProgress = !isShow && typeof media?.extra?.progress === 'number'
    ? (media.extra.progress as number)
    : null
  const isMovieResumeAvailable = !isShow && Boolean(media?.extra?.resume_available)

  // ── Show resume / progress — derived from showProgressQuery for ALL nav paths ─
  // Priority: (1) scrobbled mid-episode, (2) first unwatched episode
  const showResumeInfo = useMemo(() => {
    if (!isShow || !showProgressQuery.data) return null
    const { seasons } = showProgressQuery.data
    // 1. Check for a paused/scrobbled episode
    for (const season of (seasons ?? [])) {
      if ((season.number ?? 0) === 0) continue
      for (const ep of (season.episodes ?? [])) {
        if (ep.scrobble_progress != null && ep.scrobble_progress > 0) {
          return { season: season.number, episode: ep.number, isScrobbled: true, progress: ep.scrobble_progress }
        }
      }
    }
    // 2. Fall back to first uncompleted episode (no partial progress)
    for (const season of (seasons ?? [])) {
      if ((season.number ?? 0) === 0) continue
      for (const ep of (season.episodes ?? [])) {
        if (!ep.completed) {
          return { season: season.number, episode: ep.number, isScrobbled: false, progress: 0 }
        }
      }
    }
    return null
  }, [isShow, showProgressQuery.data])

  const showOverallProgress = useMemo(() => {
    if (!isShow || !showProgressQuery.data) return null
    const { aired, completed } = showProgressQuery.data
    if (!aired) return null
    return parseFloat(((completed ?? 0) / aired * 100).toFixed(1))
  }, [isShow, showProgressQuery.data])
  const providersQuery = useApi<WatchProvidersResponse>(
    isShow
      ? (tmdbId ? `/api/v1/catalog/detail/show/${tmdbId}/providers` : null)
      : (tmdbId ? `/api/v1/catalog/detail/movie/${tmdbId}/providers` : null),
  )

  const cast = useMemo<CastMember[]>(() => {
    if (richDetail?.credits?.cast?.length) return richDetail.credits.cast.slice(0, 12)
    return []
  }, [richDetail])

  const sources = sourcesQuery.data?.sources ?? []
  const hasLibraryTitle = detail !== null

  // First available local source — used to bypass TorrentDialog for movies
  const localSource = sources.find(
    (s) => s.source_type === 'local' && s.status !== 'missing',
  ) ?? null
  const isDetailLoading = isShow ? showDetail.isLoading : movieDetail.isLoading

  const trailerUrl = richDetail?.trailers?.[0]?.url ?? null

  function handlePlayTrailer() {
    if (!trailerUrl) return
    setTrailerPlaying(true)
    setTrailerModalUrl(trailerUrl)
  }

  function handleCloseTrailer() {
    setTrailerModalUrl(null)
    setTrailerPlaying(false)
  }

  function handlePlayEpisode(ep: EpisodeDetail, seasonNumber: number, epScrobblePct: number | null) {
    const epNum = ep.episode_number ?? null
    setTorrentSeason(seasonNumber)
    setTorrentEpisode(epNum)

    if (epScrobblePct != null && epScrobblePct > 0) {
      setResumePercent(epScrobblePct)
      setResumeModalOpen(true)
      return
    }

    // Bypass TorrentDialog when a local file exists for this episode
    const epLocalSrc = epNum != null ? findLocalEpisodeSource(seasonNumber, epNum) : null
    if (epLocalSrc && epNum != null) {
      handleLocalEpisodePlayback(epLocalSrc, seasonNumber, epNum, null).catch(console.error)
      return
    }

    setResumePercent(null)
    setTorrentOpen(true)
  }

  const title = media?.title || detail?.title || richDetail?.title || 'Detail'
  const year = media?.year ?? detail?.year ?? null
  const rating = media?.rating ?? richDetail?.vote_average ?? null
  const overview = media?.overview || detail?.overview || richDetail?.overview || 'No synopsis available.'
  const genres = (media?.genres?.length ? media.genres : richDetail?.genres) || []
  const tagline = !isShow ? (richDetail as { tagline?: string } | null)?.tagline ?? null : null
  const runtime = !isShow ? (richDetail as { runtime_minutes?: number } | null)?.runtime_minutes ?? null : null
  
  type CrewMember = { job?: string; department?: string; name?: string }
  const director = (richDetail?.credits?.crew as CrewMember[] | undefined)?.find((c) => c.job === 'Director')?.name ?? null
  const writers = (richDetail?.credits?.crew as CrewMember[] | undefined)?.filter((c) => c.department === 'Writing')?.slice(0, 2).map((c) => c.name).filter((n): n is string => !!n) ?? []
  
  useEffect(() => {
    const backdropPath =
      media?.backdrop_path ||
      richDetail?.backdrop?.url ||
      detail?.backdrop_path ||
      null
    if (backdropPath) setBackdrop(backdropPath)
    else clearBackdrop()
    return () => clearBackdrop()
  }, [media?.backdrop_path, richDetail?.backdrop?.url, detail?.backdrop_path, clearBackdrop, setBackdrop])

  function handleBack() { navigate(-1) }

  function localStreamUrl(source: SourceRow): string {
    // Include the real filename in the URL path so mpv picks the right demuxer
    // from the file extension (.mkv, .mp4, etc.). The backend ignores this suffix
    // and resolves the file via source_id only.
    const fname = source.file_path?.split('/').pop() ?? 'video'
    return `${BASE_URL}/api/v1/library/sources/${source.id}/stream/${encodeURIComponent(fname)}`
  }

  // Play a local source via the stream endpoint (supports Range / seeking in mpv).
  async function handlePlaySource(source: SourceRow) {
    if (!source.id) return
    const streamUrl = localStreamUrl(source)
    await handleTorrentStreamReady({
      source: streamUrl,
      local_source: streamUrl,
      session_id: null,
      title,
      isStream: true,
      media_kind: mediaKind,
      tmdb_id: tmdbId,
      year,
      season: null,
      episode: null,
      resumePercent: null,
    })
  }

  // Launch local playback directly, bypassing TorrentDialog.
  async function handleLocalPlayback(source: SourceRow, resumePct: number | null) {
    const streamUrl = localStreamUrl(source)
    await handleTorrentStreamReady({
      source: streamUrl,
      local_source: streamUrl,
      session_id: null,
      title,
      isStream: true,
      media_kind: mediaKind,
      tmdb_id: tmdbId,
      year,
      season: null,
      episode: null,
      resumePercent: resumePct,
    })
  }

  // Find the local source for a specific season+episode by matching the filename.
  // Handles S01E01, S1E1, s01e01, 1x01 variants with proper boundary guards.
  function findLocalEpisodeSource(season: number, episode: number): SourceRow | null {
    const re = new RegExp(
      `(?:[Ss]0*${season}[Ee]0*${episode}|\\b${season}[xX]0*${episode})(?!\\d)`,
      'i',
    )
    return (
      sources.find(
        (s) =>
          s.source_type === 'local' &&
          s.status !== 'missing' &&
          !!s.file_path &&
          re.test(s.file_path.split('/').pop() ?? ''),
      ) ?? null
    )
  }

  // Launch local playback for a specific episode, bypassing TorrentDialog.
  async function handleLocalEpisodePlayback(
    source: SourceRow,
    season: number,
    episode: number,
    resumePct: number | null,
  ) {
    const streamUrl = localStreamUrl(source)
    await handleTorrentStreamReady({
      source: streamUrl,
      local_source: streamUrl,
      session_id: null,
      title,
      isStream: true,
      media_kind: mediaKind,
      tmdb_id: tmdbId,
      year,
      season,
      episode,
      resumePercent: resumePct,
    })
  }

  async function handleTorrentStreamReady(payload: {
    source: string
    /** StreamProxy loopback URL with real filename — preferred by mpv for demux hint. */
    local_source?: string
    session_id?: string | null
    title: string
    isStream: boolean
    media_kind: 'movie' | 'tv'
    tmdb_id?: string | null
    year?: number | null
    season?: number | null
    episode?: number | null
    resumePercent?: number | null
  }) {
    // Tauri mode: open a borderless player window with the stream URL.
    // Prefer local_source (StreamProxy URL with real filename extension) over
    // source (opaque FastAPI proxy URL) so mpv gets a proper demuxer hint and
    // byte-range seeks hit the StreamProxy directly without the extra hop.
    if (isTauriRuntime()) {
      await openPlayerWindow({
        source: payload.local_source ?? payload.source,
        session_id: payload.session_id ?? null,
        title: payload.title,
        media_kind: payload.media_kind,
        tmdb_id: payload.tmdb_id ?? media?.tmdb_id ?? null,
        trakt_id: media?.trakt_id ?? null,
        year: payload.year ?? null,
        season: payload.season ?? null,
        episode: payload.episode ?? null,
        resume_percent: payload.resumePercent ?? null,
      })
      return
    }

    // Non-Tauri: fall through to backend player (VLC desktop or thin-client browser).
    try {
      const result = await playMedia({
        source: payload.source,
        session_id: payload.session_id ?? undefined,
        title: payload.title,
        media_kind: payload.media_kind,
        is_stream: payload.isStream,
        tmdb_id: payload.tmdb_id ?? undefined,
        year: payload.year ?? undefined,
        season: payload.season ?? undefined,
        episode: payload.episode ?? undefined,
        media_payload: media || undefined,
        source_type: 'debrid',
      })
      // Desktop (VLC) mode — VLC is already playing, stay on this page.
      if (result.player_mode === 'desktop') return
      // Thin-client mode — hand off to the in-browser playback page.
      navigate('/playback', {
        state: { ...payload, item: media || undefined, sourceType: 'debrid', alreadyStarted: true },
      })
    } catch {
      navigate('/playback', {
        state: { ...payload, item: media || undefined, sourceType: 'debrid' },
      })
    }
  }

  const posterUrl =
    media?.poster_path ? `${IMAGE_BASE}/w500${media.poster_path}` :
    detail?.poster_url ??
    richDetail?.poster?.url ?? null
  const backdropUrl =
    media?.backdrop_path ? `${IMAGE_BASE}/w1280${media.backdrop_path}` :
    detail?.backdrop_url ??
    richDetail?.backdrop?.url ?? null

  const collectionPayload: CollectionItemPayload | undefined = tmdbId ? {
    tmdb_id: tmdbId,
    type: isShow ? 'show' : 'movie',
    title,
    year: year ?? null,
    overview: media?.overview || richDetail?.overview || detail?.overview || null,
    poster_path: media?.poster_path || richDetail?.poster?.url || detail?.poster_path || null,
    backdrop_path: media?.backdrop_path || richDetail?.backdrop?.url || detail?.backdrop_path || null,
    rating: richDetail?.vote_average ?? rating ?? null,
    vote_count: richDetail?.vote_count ?? null,
    genres: (genres as string[]).filter((g): g is string => typeof g === 'string'),
  } : undefined

  return (
    <div className="w-full h-screen overflow-y-auto overflow-x-hidden bg-[#0a0a0a]">
      {/* HERO SECTION WITH BACKDROP */}
      <div className="relative w-full" style={{ height: '70vh', minHeight: '500px' }}>
        {backdropUrl && (
          <>
            <img 
              src={backdropUrl} 
              alt="" 
              className="absolute inset-0 w-full h-full object-cover object-[center_top]" 
            />
            <div 
              className="absolute inset-0" 
              style={{ 
                background: 'linear-gradient(to bottom, transparent 0%, transparent 30%, rgba(0,0,0,0.3) 50%, rgba(0,0,0,0.7) 70%, rgba(0,0,0,0.95) 90%, #0a0a0a 100%)' 
              }} 
            />
          </>
        )}
        {!backdropUrl && <div className="absolute inset-0 bg-gradient-to-b from-neutral-900/40 to-[#0a0a0a]" />}

        {/* BACK BUTTON */}
        <button 
          onClick={handleBack} 
          className="absolute z-30 flex items-center justify-center gap-2 text-[15px] font-medium text-white bg-black/90 backdrop-blur-md border border-white px-5 py-2.5 rounded-lg hover:bg-black/80 hover:border-white/30 transition-all duration-200"
          style={{ top: 'clamp(20px, 2.5vw, 48px)', left: 'clamp(20px, 2.5vw, 48px)', width: '100px', height: '40px' }}
        >
          <ArrowLeft size={18} /> Back
        </button>

        {/* ACTION BUTTONS */}
        <div 
          className="absolute z-30 flex items-center gap-3"
          style={{ top: 'clamp(20px, 2.5vw, 48px)', right: 'clamp(20px, 2.5vw, 48px)' }}
        >
          {trailerUrl && (
            <button 
              onClick={handlePlayTrailer} 
              disabled={trailerPlaying} 
              className="flex items-center justify-center gap-2 px-8 py-3.5 rounded-lg text-base font-semibold text-white transition-all duration-200 hover:-translate-y-0.5"
              style={{ 
                background: 'rgb(9, 93, 229)', 
                boxShadow: '0 4px 16px rgba(229, 9, 20, 0.4)',
                width: '150px',
                height: '40px'
              }}
            >
              {trailerPlaying ? (
                <Loader2 size={18} className="animate-spin" />
              ) : (
                <Play size={18} fill="white" />
              )}
              <span>Play Trailer</span>
            </button>
          )}
          
          <button
            onClick={() => {
              if (isShow && showResumeInfo) {
                const { season, episode: epNum, isScrobbled, progress } = showResumeInfo
                setTorrentSeason(season)
                setTorrentEpisode(epNum)
                if (isScrobbled) {
                  setResumePercent(progress)
                  setResumeModalOpen(true)
                  return  // modal decides next step
                }
                // No scrobble — play immediately via local source if available
                const epSrc = epNum != null ? findLocalEpisodeSource(season, epNum) : null
                if (epSrc && epNum != null) {
                  handleLocalEpisodePlayback(epSrc, season, epNum, null).catch(console.error)
                  return
                }
              } else if (!isShow && isMovieResumeAvailable && movieResumeProgress != null) {
                setResumePercent(movieResumeProgress)
                setResumeModalOpen(true)
                return  // modal decides whether to open TorrentDialog
              }
              // Movies with a local source skip the TorrentDialog entirely
              if (!isShow && localSource) {
                handleLocalPlayback(localSource, null).catch(console.error)
                return
              }
              setResumePercent(null)
              setTorrentOpen(true)
            }}
            className="flex items-center justify-center gap-2 px-8 py-3.5 rounded-lg text-base font-semibold text-white transition-all duration-200 hover:-translate-y-0.5"
            style={{
              background: (isShow ? !!showResumeInfo?.isScrobbled : isMovieResumeAvailable)
                ? 'rgb(217, 119, 6)'
                : 'rgb(229, 9, 20)',
              boxShadow: (isShow ? !!showResumeInfo?.isScrobbled : isMovieResumeAvailable)
                ? '0 4px 16px rgba(217,119,6,0.4)'
                : '0 4px 16px rgba(229, 9, 20, 0.4)',
              minWidth: '150px',
              height: '40px',
              paddingLeft: '16px',
              paddingRight: '16px',
            }}
          >
            <Play size={18} fill="white" />
            <span>
              {isShow
                ? showResumeInfo
                  ? (showResumeInfo.isScrobbled
                      ? `Resume S${String(showResumeInfo.season).padStart(2, '0')}E${String(showResumeInfo.episode ?? 1).padStart(2, '0')}`
                      : `Next S${String(showResumeInfo.season).padStart(2, '0')}E${String(showResumeInfo.episode ?? 1).padStart(2, '0')}`)
                  : 'Play'
                : isMovieResumeAvailable
                  ? 'Resume'
                  : 'Play'}
            </span>
          </button>
          
          <button
            onClick={() => toggleWishlisted(collectionPayload)}
            title={isWishlisted ? 'Remove from Wishlist' : 'Add to Wishlist'}
            className="w-12 h-12 rounded-full backdrop-blur-3xl flex items-center justify-center hover:scale-110 transition-all duration-200"
            style={{
              background: isWishlisted ? 'rgba(16,185,129,0.25)' : 'rgba(0,0,0,0.40)',
              border: isWishlisted ? '1px solid rgba(16,185,129,0.60)' : '1px solid rgba(255,255,255,0.20)',
              color: isWishlisted ? 'rgb(52,211,153)' : 'white',
            }}
          >
            {isWishlisted ? <CheckCircle2 size={20} /> : <Plus size={20} />}
          </button>
          <button className="w-12 h-12 rounded-full bg-black/40 backdrop-blur-3xl border border-white/20 flex items-center justify-center text-white hover:bg-white/20 hover:border-white/40 hover:scale-110 transition-all duration-200">
            <Share2 size={18} />
          </button>
          <button
            onClick={() => toggleLiked(collectionPayload)}
            title={isLiked ? 'Unlike' : 'Like'}
            className="w-12 h-12 rounded-full backdrop-blur-3xl flex items-center justify-center hover:scale-110 transition-all duration-200"
            style={{
              background: isLiked ? 'rgba(239,68,68,0.25)' : 'rgba(0,0,0,0.40)',
              border: isLiked ? '1px solid rgba(239,68,68,0.60)' : '1px solid rgba(255,255,255,0.20)',
              color: isLiked ? 'rgb(248,113,113)' : 'white',
            }}
          >
            <Heart size={18} fill={isLiked ? 'currentColor' : 'none'} />
          </button>
        </div>

        {/* POSTER & METADATA - POSITIONED ABSOLUTELY AT BOTTOM OF HERO */}
        <div 
          className="absolute bottom-0 left-0 right-0 z-20 flex items-end gap-8"
          style={{ 
            paddingLeft: 'clamp(20px, 2.5vw, 48px)', 
            paddingRight: 'clamp(20px, 2.5vw, 48px)',
            paddingBottom: '24px',
            transform: 'translateY(50%)'
          }}
        >
          {/* POSTER */}
          <div 
            className="flex-shrink-0 rounded-xl overflow-hidden border-2 border-white/10"
            style={{ 
              width: 'clamp(200px, 18vw, 280px)', 
              height: 'clamp(300px, 27vw, 420px)',
              boxShadow: '0 8px 32px rgba(0, 0, 0, 0.6)'
            }}
          >
            {posterUrl ? (
              <img src={posterUrl} alt={title} className="w-full h-full object-cover" />
            ) : (
              <div className="w-full h-full bg-white/5 flex items-center justify-center text-white/30 text-sm">
                No Poster
              </div>
            )}
          </div>

          {/* METADATA */}
          <div className="flex-1 self-start" style={{ maxWidth: '700px', paddingTop: 'clamp(40px, 6vh, 80px)' }}>
            <h1 
              className="font-bold text-white" 
              style={{ 
                fontSize: 'clamp(32px, 3.5vw, 56px)', 
                lineHeight: 1.1, 
                textShadow: '2px 4px 16px rgba(0,0,0,0.9)',
                marginBottom: '16px',
              }}
            >
              {title}
            </h1>
            
            {tagline && (
              <p 
                className="text-white/80 italic" 
                style={{ 
                  fontSize: 'clamp(16px, 1.2vw, 18px)', 
                  textShadow: '1px 2px 8px rgba(0,0,0,0.9)',
                  marginBottom: '16px',
                }}
              >
                {tagline}
              </p>
            )}

            <div className="flex items-center gap-5 text-base flex-wrap" style={{ marginBottom: '16px' }}>
              <RatingBadges
                tmdbRating={richDetail?.vote_average ?? rating}
                imdbRating={imdbRating.data?.rating}
                size="md"
              />
              {year && <span className="text-white font-medium">{year}</span>}
              {runtime && <span className="text-white font-medium">{runtime} min</span>}
            </div>

            <div className="flex flex-wrap gap-5" style={{ marginBottom: '16px' }}>
              <Tags size={25} className="text-white" />
              {genres.map((g: string) => (
                <span 
                  key={g} 
                  // className="bg-white/10 backdrop-blur-sm border border-white/20 px-5 py-2.5 rounded-full text-white/90 capitalize font-medium text-base" style={{ width: '100px', height: '30px' }}
                >
                  {g}
                </span>
              ))}
            </div>

            <p 
              className="text-white/85 leading-relaxed" 
              style={{ 
                fontSize: 'clamp(15px, 1.1vw, 18px)', 
                lineHeight: 1.7, 
                maxWidth: '650px', 
                textShadow: '1px 2px 8px rgba(0,0,0,0.8)',
                display: '-webkit-box',
                // WebkitLineClamp: 3,
                WebkitBoxOrient: 'vertical',
                overflow: 'hidden'
              }}
            >
              {overview}
            </p>
          </div>
        </div>
      </div>

      {/* SPACER FOR OVERLAPPING POSTER */}
      <div style={{ height: 'clamp(180px, 23vw, 240px)' }} />

      {/* PROGRESS BAR — shows completed % for shows, scrobble % for movies */}
      {(() => {
        const pct = isShow ? showOverallProgress : movieResumeProgress
        if (pct == null || pct <= 0) return null
        const label = isShow
          ? `${pct}% completed`
          : `${Math.round(pct)}% watched`
        return (
          <div
            style={{
              paddingLeft: 'clamp(20px, 2.5vw, 48px)',
              paddingRight: 'clamp(20px, 2.5vw, 48px)',
              paddingBottom: '20px',
            }}
          >
            <div className="flex items-center gap-3">
              <div className="flex-1 h-1.5 rounded-full bg-white/10 overflow-hidden">
                <div
                  className="h-full bg-amber-400 rounded-full transition-all"
                  style={{ width: `${Math.min(100, pct)}%` }}
                />
              </div>
              <span className="text-white/50 font-medium text-xs flex-shrink-0">
                {label}
              </span>
            </div>
          </div>
        )
      })()}

      {/* DIRECTOR/WRITER/YEAR ROW */}
      {!isDetailLoading && (director || writers.length > 0) && (
        <section 
          className="bg-[#0a0a0a] border-t border-white/5"
          style={{ 
            paddingLeft: 'clamp(20px, 2.5vw, 48px)',
            paddingRight: 'clamp(20px, 2.5vw, 48px)',
            paddingTop: '40px',
            paddingBottom: '32px'
          }}
        >
          <div className="flex gap-10 flex-wrap">
            {director && (
              <div className="flex flex-col gap-1">
                <span className="text-white/50 font-medium uppercase tracking-wide text-xs">Director</span>
                <span className="text-white/90 font-semibold text-base">{director}</span>
              </div>
            )}
            {writers.length > 0 && (
              <div className="flex flex-col gap-1">
                <span className="text-white/50 font-medium uppercase tracking-wide text-xs">
                  Writer{writers.length > 1 ? 's' : ''}
                </span>
                <span className="text-white/90 font-semibold text-base">{writers.join(', ')}</span>
              </div>
            )}
            {year && (
              <div className="flex flex-col gap-1">
                <span className="text-white/50 font-medium uppercase tracking-wide text-xs">Year</span>
                <span className="text-white/90 font-semibold text-base">{year}</span>
              </div>
            )}
          </div>
        </section>
      )}

      {/* EPISODES & SEASONS SECTION */}
      {isShow && seasonsQuery.data && seasonsQuery.data.seasons.length > 0 && (
        <section
          className="bg-[#0a0a0a] border-t border-white/5"
          style={{
            paddingLeft: 'clamp(20px, 2.5vw, 48px)',
            paddingRight: 'clamp(20px, 2.5vw, 48px)',
            paddingTop: '48px',
            paddingBottom: '64px',
          }}
        >
          {/* Section header */}
          <div className="flex items-baseline gap-4" style={{ marginBottom: '28px' }}>
            <h2 className="text-white font-bold" style={{ fontSize: 'clamp(22px, 1.75vw, 28px)' }}>
              Episodes
            </h2>
            {seasonsQuery.data.seasons[selectedSeasonIdx]?.episode_count != null && (
              <span className="text-white/40 font-medium" style={{ fontSize: 14 }}>
                {seasonsQuery.data.seasons[selectedSeasonIdx].episode_count} episodes
              </span>
            )}
          </div>

          {/* Season selector — accent pill tabs with scroll chevrons */}
          <div className="relative flex items-center gap-2" style={{ marginBottom: '28px' }}>
            <button
              onClick={() => seasonScrollRef.current?.scrollBy({ left: -300, behavior: 'smooth' })}
              className="flex-shrink-0 flex items-center justify-center rounded-full transition-colors cursor-pointer hover:bg-white/10"
              style={{ width: 32, height: 32, color: 'rgba(255,255,255,0.55)' }}
            >
              <ChevronLeft size={25} />
            </button>

            <div
              ref={seasonScrollRef}
              className="flex gap-2 overflow-x-auto pb-1"
              style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
            >
              {seasonsQuery.data.seasons.map((season: SeasonDetail, idx: number) => (
                <button
                  key={season.season_number}
                  onClick={() => setSelectedSeasonIdx(idx)}
                  className="flex-shrink-0 flex items-center gap-1.5 rounded-full font-semibold text-sm transition-all duration-200 cursor-pointer"
                  style={{
                    padding: '7px 18px',
                    background: idx === selectedSeasonIdx ? 'var(--accent)' : 'rgba(255,255,255,0.06)',
                    border: idx === selectedSeasonIdx ? 'none' : '1px solid rgba(255,255,255,0.10)',
                    color: idx === selectedSeasonIdx ? '#000' : 'rgba(255,255,255,0.55)',
                    boxShadow: idx === selectedSeasonIdx ? '0 0 14px rgba(1,180,228,0.35)' : undefined,
                  }}
                >
                  <span>S{String(season.season_number).padStart(2, '0')}</span>
                  {season.episode_count != null && (
                    <span className="opacity-70" style={{ fontSize: 11 }}>
                      · {season.episode_count}ep
                    </span>
                  )}
                </button>
              ))}
            </div>

            <button
              onClick={() => seasonScrollRef.current?.scrollBy({ left: 300, behavior: 'smooth' })}
              className="flex-shrink-0 flex items-center justify-center rounded-full transition-colors cursor-pointer hover:bg-white/10"
              style={{ width: 32, height: 32, color: 'rgba(255,255,255,0.55)' }}
            >
              <ChevronRight size={25} />
            </button>
          </div>

          {/* Episode cards */}
          {seasonsQuery.data.seasons[selectedSeasonIdx] && (
            <div className="space-y-3">
              {seasonsQuery.data.seasons[selectedSeasonIdx].episodes?.map((ep) => {
                const seasonNum = seasonsQuery.data!.seasons[selectedSeasonIdx].season_number
                const epCode = `S${String(seasonNum).padStart(2, '0')}E${String(ep.episode_number ?? 1).padStart(2, '0')}`
                const stillUrl = ep.still_frame?.url
                  ? `${IMAGE_BASE}/w300${ep.still_frame.url}`
                  : null

                // Watched progress status from Trakt
                const progressSeason = showProgressQuery.data?.seasons?.find(
                  (s) => s.number === seasonNum
                )
                const progressEp = progressSeason?.episodes?.find(
                  (e) => e.number === ep.episode_number
                )
                const isWatched = progressEp?.completed === true
                // isResumeEp: the episode showProgressQuery resolved as the resume point
                const isResumeEp =
                  showResumeInfo?.season === seasonNum &&
                  showResumeInfo?.episode === ep.episode_number
                // isScrobbleEp: this specific episode has a partial scrobble progress
                const epScrobblePct =
                  (progressEp?.scrobble_progress != null &&
                   progressEp.scrobble_progress > 0)
                    ? progressEp.scrobble_progress
                    : null
                // Local source availability — drives play button style and HDD badge
                const epLocalSrc =
                  ep.episode_number != null
                    ? findLocalEpisodeSource(seasonNum, ep.episode_number)
                    : null

                return (
                  <div
                    key={ep.id}
                    className="group relative flex items-stretch rounded-xl overflow-hidden border transition-all duration-200 hover:shadow-[0_4px_24px_rgba(0,0,0,0.5)]"
                    style={{
                      background: isResumeEp ? 'rgba(217,119,6,0.08)' : isWatched ? 'rgba(255,255,255,0.02)' : 'rgba(255,255,255,0.03)',
                      borderColor: isResumeEp ? 'rgba(217,119,6,0.4)' : isWatched ? 'rgba(255,255,255,0.04)' : 'rgba(255,255,255,0.07)',
                      minHeight: '110px',
                      opacity: isWatched && !isResumeEp ? 0.65 : 1,
                    }}
                  >
                    {/* Scrobble progress bar — full card width, top edge */}
                    {epScrobblePct != null && (
                      <div className="absolute top-0 left-0 right-0 h-[3px] bg-white/10 z-20">
                        <div
                          className="h-full bg-amber-400"
                          style={{ width: `${Math.min(100, epScrobblePct)}%` }}
                        />
                      </div>
                    )}

                    {/* Still frame */}
                    <div
                      className="relative flex-shrink-0 overflow-hidden bg-white/[0.04]"
                      style={{ width: 'clamp(160px, 14vw, 220px)', alignSelf: 'stretch', minHeight: '100%' }}
                    >
                      {stillUrl ? (
                        <>
                          <img
                            src={stillUrl}
                            alt={ep.title}
                            className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                          />
                          <div className="absolute inset-0 bg-gradient-to-r from-transparent to-black/20" />
                        </>
                      ) : (
                        <div className="w-full h-full flex items-center justify-center" style={{ minHeight: '110px' }}>
                          <Play size={22} className="text-white/20" />
                        </div>
                      )}
                      {/* SxxExx badge */}
                      <div
                        className="absolute bottom-2 left-2 font-bold text-white/90 tracking-wide"
                        style={{
                          fontSize: 11,
                          background: 'rgba(0,0,0,0.72)',
                          backdropFilter: 'blur(4px)',
                          padding: '2px 7px',
                          borderRadius: 5,
                        }}
                      >
                        {epCode}
                      </div>

                      {/* Watched tick overlay */}
                      {isWatched && (
                        <div className="absolute top-2 right-2 text-emerald-400">
                          <CheckCircle2 size={18} fill="rgba(0,0,0,0.5)" />
                        </div>
                      )}

                      {/* Local file indicator */}
                      {epLocalSrc && (
                        <div
                          className="absolute bottom-2 right-2 text-cyan-400"
                          title="Local file available"
                        >
                          <HardDrive size={14} />
                        </div>
                      )}
                    </div>

                    {/* Metadata + Play */}
                    <div className="flex flex-1 items-center gap-4 bg-white/10 px-5 py-4 min-w-0">
                      <div className="flex-1 min-w-0" style={{ marginLeft: '20px' }}>
                        <p
                          className="text-white font-semibold truncate"
                          style={{ fontSize: 'clamp(14px, 1vw, 17px)', marginBottom: '5px' }}
                        >
                          {ep.title || `Episode ${ep.episode_number}`}
                        </p>

                        <div className="flex items-center gap-3 flex-wrap" style={{ marginBottom: ep.overview ? '8px' : 0 }}>
                          {ep.air_date && (
                            <span className="text-white/40 text-xs">{ep.air_date}</span>
                          )}
                          {ep.runtime_minutes != null && (
                            <span className="text-white/40 text-xs">{ep.runtime_minutes} min</span>
                          )}
                          {ep.vote_average != null && (
                            <span className="flex items-center gap-1 text-yellow-400/90 font-medium text-xs">
                              <Star size={10} fill="currentColor" />
                              {ep.vote_average.toFixed(1)}
                            </span>
                          )}
                        </div>

                        {ep.overview && (
                          <p
                            className="text-white/45 leading-relaxed line-clamp-2"
                            style={{ fontSize: 'clamp(12px, 0.75vw, 14px)' }}
                          >
                            {ep.overview}
                          </p>
                        )}
                      </div>

                      <button
                        onClick={() => handlePlayEpisode(ep, seasonNum, epScrobblePct)}
                        className="flex-shrink-0 flex items-center gap-2 font-semibold cursor-pointer transition-all duration-200 hover:scale-105 hover:brightness-110"
                        style={{
                          padding: '10px 22px',
                          fontSize: 13,
                          borderRadius: 8,
                          background: epScrobblePct != null
                            ? 'rgba(217,119,6,0.9)'
                            : 'rgba(229,9,20,0.85)',
                          boxShadow: epScrobblePct != null
                            ? '0 2px 12px rgba(217,119,6,0.4)'
                            : '0 2px 12px rgba(229,9,20,0.3)',
                          color: '#fff',
                          whiteSpace: 'nowrap',
                          marginRight: '20px',
                        }}
                      >
                        {epLocalSrc
                          ? <HardDrive size={14} />
                          : <Play size={14} fill="currentColor" />}
                        {epScrobblePct != null ? 'Resume' : 'Play'}
                      </button>
                    </div>
                  </div>
                )
              })}

              {!seasonsQuery.data.seasons[selectedSeasonIdx].episodes?.length && (
                <div className="flex flex-col items-center justify-center py-16 text-white/30">
                  <Play size={32} className="mb-3 opacity-40" />
                  <p className="text-sm">No episode details available for this season.</p>
                </div>
              )}
            </div>
          )}
        </section>
      )}

      {/* CAST SECTION */}
      {!isDetailLoading && cast.length > 0 && (
        <section 
          className="bg-[#0a0a0a] border-t border-white/5"
          style={{ 
            paddingLeft: 'clamp(20px, 2.5vw, 48px)',
            paddingRight: 'clamp(20px, 2.5vw, 48px)',
            paddingTop: '48px',
            paddingBottom: '56px'
          }}
        >
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-white font-bold" style={{ fontSize: 'clamp(22px, 1.75vw, 28px)', marginBottom: '20px' }}>
              Cast
            </h2>
            <button className="text-white/60 hover:text-white/90 transition-colors text-sm font-medium">
              View All
            </button>
          </div>
          <div className="relative">
            <div 
              className="flex gap-4 overflow-x-auto pb-2"
              style={{ 
                scrollbarWidth: 'none',
                msOverflowStyle: 'none',
                WebkitMaskImage: 'linear-gradient(to right, black 0%, black 85%, transparent 100%)',
                maskImage: 'linear-gradient(to right, black 0%, black 85%, transparent 100%)'
              }}
            >
              {cast.map((person, idx) => (
                <div 
                  key={`${person.name}-${idx}`} 
                  className="flex-shrink-0 bg-white/[0.03] border border-white/[0.08] rounded-xl overflow-hidden hover:-translate-y-2 hover:shadow-[0_12px_24px_rgba(0,0,0,0.5)] hover:bg-white/[0.05] hover:border-white/[0.15] transition-all duration-200 cursor-pointer"
                  style={{ width: '160px' }}
                >
                  <div className="w-full bg-white/5 flex items-center justify-center" style={{ height: '200px' }}>
                    {(person.profile_image?.url || person.profile_path) ? (
                      <img 
                        src={`${IMAGE_BASE}/w300${person.profile_image?.url || person.profile_path}`} 
                        alt={person.name} 
                        className="w-full h-full object-cover" 
                      />
                    ) : (
                      <span className="text-white/30 text-sm">No Photo</span>
                    )}
                  </div>
                  <div className="p-3">
                    <p className="text-white/90 font-semibold truncate text-[15px]">{person.name}</p>
                    {person.character && (
                      <p className="text-white/50 truncate text-[13px]">{person.character}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* WHERE TO WATCH SECTION */}
      {!isDetailLoading && providersQuery.data && (providersQuery.data.streaming.length > 0 || providersQuery.data.rent.length > 0 || providersQuery.data.buy.length > 0) && (
        <section 
          className="bg-[#0a0a0a] border-t border-white/5"
          style={{ 
            paddingLeft: 'clamp(20px, 2.5vw, 48px)',
            paddingRight: 'clamp(20px, 2.5vw, 48px)',
            paddingTop: '48px',
            paddingBottom: '56px',
          }}
        >
          <h2 className="text-white font-bold mb-6" style={{ fontSize: 'clamp(22px, 1.75vw, 28px)', marginBottom: '10px' }}>
            Where to Watch
          </h2>

          {providersQuery.data.streaming.length > 0 && (
            <div className="mb-8">
              <p className="text-white/70 uppercase tracking-wider font-semibold mb-4 text-base" style={{ marginBottom: '16px' }}>
                Streaming Now
              </p>
              <div className="flex flex-wrap gap-4" >
                {providersQuery.data.streaming.map((p) => (
                  <div 
                    key={p.provider_id} 
                    className="hover:scale-110 transition-all duration-200 cursor-pointer" 
                  >
                    {p.logo_path ? (
                      <img 
                        src={`${IMAGE_BASE}/w92${p.logo_path}`} 
                        alt={p.provider_name} 
                        className="w-14 h-14 rounded-xl shadow-[0_2px_8px_rgba(0,0,0,0.3)]" 
                      />
                    ) : (
                      <div className="w-14 h-14 rounded-xl bg-white/5 flex items-center justify-center text-white/50 text-xs font-semibold" >
                        {p.provider_name.slice(0, 3)}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {(providersQuery.data.rent.length > 0 || providersQuery.data.buy.length > 0) && (
            <div>
              <p className="text-white/70 uppercase tracking-wider font-semibold mb-4 text-base">
                Rent / Buy
              </p>
              <div className="flex flex-wrap gap-4">
                {[...providersQuery.data.rent, ...providersQuery.data.buy].map((p) => (
                  <div 
                    key={`${p.provider_id}-${p.provider_name}`} 
                    className="hover:scale-110 transition-all duration-200 cursor-pointer"
                  >
                    {p.logo_path ? (
                      <img 
                        src={`${IMAGE_BASE}/w92${p.logo_path}`} 
                        alt={p.provider_name} 
                        className="w-14 h-14 rounded-xl shadow-[0_2px_8px_rgba(0,0,0,0.3)]"  
                      />
                    ) : (
                      <div className="w-14 h-14 rounded-xl bg-white/5 flex items-center justify-center text-white/50 text-xs font-semibold" >
                        {p.provider_name.slice(0, 3)}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}
        </section>
      )}

      {providersQuery.isLoading && (
        <div className="py-8">
          <LoadingSpinner />
        </div>
      )}

      {/* LOCAL SOURCES SECTION */}
      {sources.length > 0 && (
        <section 
          className="bg-[#0a0a0a] border-t border-white/5"
          style={{ 
            paddingLeft: 'clamp(20px, 2.5vw, 48px)',
            paddingRight: 'clamp(20px, 2.5vw, 48px)',
            paddingTop: '40px',
            paddingBottom: '40px'
          }}
        >
          <h2 className="text-white font-bold mb-4" style={{ fontSize: 'clamp(22px, 1.75vw, 28px)' }}>
            Local Sources
          </h2>
          <div className="space-y-3">
            {sources.map((source) => (
              <div 
                key={source.id} 
                className="flex items-center justify-between gap-4 bg-white/[0.03] border border-white/[0.08] rounded-lg p-4 hover:bg-white/[0.05] transition-colors"
              >
                <div className="min-w-0 flex-1 flex items-center gap-3">
                  <span className="text-white/50 text-xs font-mono font-semibold uppercase px-2 py-1 bg-white/5 rounded">
                    {source.quality || source.source_type}
                  </span>
                  <span className="text-white/90 truncate font-mono text-sm">
                    {source.file_path || source.url}
                  </span>
                </div>
                <button 
                  onClick={() => handlePlaySource(source)} 
                  className="flex items-center gap-2 bg-white/10 hover:bg-white/15 border border-white/20 px-4 py-2 rounded-lg text-white font-semibold text-sm transition-colors"
                >
                  <Play size={14} /> Play
                </button>
              </div>
            ))}
          </div>
        </section>
      )}

      {!hasLibraryTitle && (
        <div style={{ 
          paddingLeft: 'clamp(20px, 2.5vw, 48px)',
          paddingRight: 'clamp(20px, 2.5vw, 48px)',
          paddingTop: '32px',
          paddingBottom: '32px'
        }}>
          <p className="text-white/40 text-sm">
            Add this title to your library to see local file sources.
          </p>
        </div>
      )}

      {/* Resume modal — appears before TorrentDialog opens */}
      {resumeModalOpen && (
        <div
          className="fixed inset-0 z-[60] flex items-center justify-center"
          style={{ background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)' }}
          onClick={() => setResumeModalOpen(false)}
        >
          <div
            className="flex flex-col gap-6 border border-white/10 rounded-2xl shadow-2xl"
            style={{ width: 360, padding: '32px', background: 'rgba(12,12,16,0.98)' }}
            onClick={(e) => e.stopPropagation()}
          >
            <div>
              <h3 className="text-white font-bold text-xl" style={{ marginBottom: 8 }}>Resume Playback</h3>
              <p className="text-white/50 text-sm leading-relaxed">
                {resumePercent != null ? `You were ${Math.round(resumePercent)}% through. ` : ''}
                Continue from where you left off or start over?
              </p>
            </div>
            <div className="flex flex-col gap-3">
              <button
                onClick={() => {
                  setResumeModalOpen(false)
                  if (isShow && torrentSeason != null && torrentEpisode != null) {
                    const epSrc = findLocalEpisodeSource(torrentSeason, torrentEpisode)
                    if (epSrc) {
                      handleLocalEpisodePlayback(epSrc, torrentSeason, torrentEpisode, resumePercent).catch(console.error)
                      return
                    }
                  } else if (!isShow && localSource) {
                    handleLocalPlayback(localSource, resumePercent).catch(console.error)
                    return
                  }
                  setTorrentOpen(true)
                }}
                className="w-full py-3 rounded-xl text-white font-semibold text-base transition-all hover:brightness-110"
                style={{ background: 'rgb(217,119,6)', boxShadow: '0 4px 16px rgba(217,119,6,0.35)', height: '40px' }}
              >
                Continue Watching
              </button>
              <button
                onClick={() => {
                  setResumePercent(null)
                  setResumeModalOpen(false)
                  if (isShow && torrentSeason != null && torrentEpisode != null) {
                    const epSrc = findLocalEpisodeSource(torrentSeason, torrentEpisode)
                    if (epSrc) {
                      handleLocalEpisodePlayback(epSrc, torrentSeason, torrentEpisode, null).catch(console.error)
                      return
                    }
                  } else if (!isShow && localSource) {
                    handleLocalPlayback(localSource, null).catch(console.error)
                    return
                  }
                  setTorrentOpen(true)
                }}
                className="w-full py-3 rounded-xl font-semibold text-base border transition-all hover:border-white/20 hover:text-white"
                style={{ background: 'rgba(255,255,255,0.04)', borderColor: 'rgba(255,255,255,0.10)', color: 'rgba(255,255,255,0.65)', height: '40px' }}
              >
                Start Over
              </button>
              <button
                onClick={() => setResumeModalOpen(false)}
                className="text-white/35 text-sm hover:text-white/55 transition-colors"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      <TorrentDialog
        open={torrentOpen}
        title={title}
        mediaKind={mediaKind}
        onClose={() => { setTorrentOpen(false); setTorrentSeason(null); setTorrentEpisode(null); setResumePercent(null) }}
        item={media || undefined}
        year={year ?? undefined}
        season={torrentSeason}
        episode={torrentEpisode}
        resumePercent={resumePercent}
        onStreamReady={handleTorrentStreamReady}
      />

      <TrailerDialog url={trailerModalUrl} onClose={handleCloseTrailer} />
    </div>
  )
}
