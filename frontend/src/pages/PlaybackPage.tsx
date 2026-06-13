import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { scrobbleStart, scrobbleStop, usePlayerStatus, playMedia, pausePlayback, resumePlayback, stopPlayback, seekPlayback, setVolume } from '@/hooks/usePlayer'
import PlaybackControls from '@/components/media/PlaybackControls'
import SubtitleDialog from '@/components/media/SubtitleDialog'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import type { MediaItem, PlayerPlayRequest } from '@/lib/types'

type PlaybackLocationState = PlayerPlayRequest & {
  item?: MediaItem
  sourceType?: string
  isStream?: boolean
  /** Set to true when the caller has already sent POST /player/play before navigating here. */
  alreadyStarted?: boolean
}

export default function PlaybackPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const state = location.state as PlaybackLocationState | null
  const { data: status, mutate } = usePlayerStatus()
  const [subtitleOpen, setSubtitleOpen] = useState(false)
  const [started, setStarted] = useState(false)
  const [scrobbleStarted, setScrobbleStarted] = useState(false)
  const lastKnownProgress = useRef(0)
  const explicitStopRequested = useRef(false)
  const scrobbleStopSent = useRef(false)

  const playRequest = useMemo<PlayerPlayRequest | null>(() => {
    if (!state?.source) return null
    return {
      source: state.source,
      session_id: state.session_id ?? undefined,
      title: state.title || state.item?.title,
      media_kind: state.media_kind || (state.item?.type === 'show' ? 'tv' : 'movie'),
      season: state.season ?? undefined,
      episode: state.episode ?? undefined,
      year: state.year ?? state.item?.year ?? undefined,
      is_stream: state.isStream ?? state.is_stream,
      tmdb_id: state.tmdb_id ?? state.item?.tmdb_id ?? undefined,
      media_payload: state.item ?? undefined,
      source_type: state.sourceType ?? 'local',
    }
  }, [state])

  const buildScrobbleContext = () => {
    if (!playRequest) return null
    const mediaType = playRequest.media_kind === 'tv' ? 'episode' : 'movie'
    const tmdbId = playRequest.tmdb_id ? Number(playRequest.tmdb_id) : null
    const traktId = state?.item?.trakt_id ? Number(state.item.trakt_id) : null

    const mediaPayload: Record<string, unknown> = {
      title: playRequest.title,
      year: playRequest.year ?? state?.item?.year ?? undefined,
      ids: {
        ...(tmdbId ? { tmdb: tmdbId } : {}),
        ...(traktId ? { trakt: traktId } : {}),
      },
    }

    const showPayload = mediaType === 'episode'
      ? {
          title: state?.item?.title || playRequest.title,
          year: playRequest.year ?? state?.item?.year ?? undefined,
          ids: {
            ...(tmdbId ? { tmdb: tmdbId } : {}),
            ...(traktId ? { trakt: traktId } : {}),
          },
        }
      : undefined

    return {
      session_id: playRequest.session_id ?? null,
      media_type: mediaType as 'movie' | 'episode',
      media: mediaPayload,
      show: showPayload,
    }
  }

  useEffect(() => {
    if (!status) return
    const duration = status.duration_ms ?? 0
    const position = status.position_ms ?? 0
    if (duration > 0 && position >= 0) {
      const progress = Math.max(0, Math.min(100, (position / duration) * 100))
      lastKnownProgress.current = progress
    }
  }, [status])

  const refreshPlaybackStatus = useCallback(async () => {
    await mutate()
  }, [mutate])

  useEffect(() => {
    const shouldSkipForAlreadyStarted = Boolean(state?.alreadyStarted)

    // Skip if already started (caller sent POST /player/play before navigating)
    if (!playRequest || started || shouldSkipForAlreadyStarted) {
      if (shouldSkipForAlreadyStarted && !started) setStarted(true)
      return
    }
    let mounted = true

    playMedia(playRequest)
      .then(() => {
        if (mounted) {
          setStarted(true)
          void refreshPlaybackStatus()
        }
      })
      .catch(() => {
        if (mounted) setStarted(true)
      })
    return () => {
      mounted = false
    }
  }, [playRequest, refreshPlaybackStatus, started, state?.alreadyStarted])

  useEffect(() => {
    if (!playRequest || !started || scrobbleStarted) return
    const scrobbleContext = buildScrobbleContext()
    if (!scrobbleContext) return

    void scrobbleStart({
      ...scrobbleContext,
      progress: lastKnownProgress.current,
    }).finally(() => {
      setScrobbleStarted(true)
    })
  }, [playRequest, scrobbleStarted, started])

  useEffect(() => {
    const scrobbleContext = buildScrobbleContext()
    if (!started || !scrobbleStarted || !status || !scrobbleContext) return
    if (explicitStopRequested.current || scrobbleStopSent.current) return

    const stateValue = (status.state || '').toLowerCase()
    if (stateValue !== 'stopped' && stateValue !== 'ended') return

    scrobbleStopSent.current = true
    void scrobbleStop({
      ...scrobbleContext,
      progress: 100,
    })
  }, [scrobbleStarted, started, status])

  async function handleTogglePlayPause() {
    if (status?.playing) {
      await pausePlayback()
    } else {
      await resumePlayback()
    }
    await refreshPlaybackStatus()
  }

  async function handleStop() {
    explicitStopRequested.current = true

    const scrobbleContext = buildScrobbleContext()
    if (scrobbleContext && scrobbleStarted && !scrobbleStopSent.current) {
      scrobbleStopSent.current = true

      try {
        await scrobbleStop({
          ...scrobbleContext,
          progress: lastKnownProgress.current,
        })
      } catch {
        // Best effort: stopping local playback should still proceed.
      }
    }

    await stopPlayback()
    navigate(-1)
  }

  async function handleSeek(positionMs: number) {
    await seekPlayback(positionMs)
    await refreshPlaybackStatus()
  }

  async function handleVolume(volume: number) {
    await setVolume(volume)
    await refreshPlaybackStatus()
  }

  return (
    <div className="relative h-full overflow-y-auto p-[clamp(12px,1.25vw,24px)] space-y-[clamp(12px,1.25vw,24px)]">
      <div>
        <h1 className="text-page font-extrabold tracking-tight text-fg-white">Playback</h1>
        <p className="text-fg-muted text-subtitle">{state?.title || 'Playing media'}</p>
      </div>

      {!state?.source && (
        <div className="rounded-card border border-white/5 bg-bg-panel p-[clamp(12px,1.25vw,24px)]">
          <p className="text-fg-muted text-body">No playback source provided.</p>
        </div>
      )}

      {!status && <LoadingSpinner />}

      <PlaybackControls
        status={status}
        onTogglePlayPause={handleTogglePlayPause}
        onStop={handleStop}
        onSeek={handleSeek}
        onVolume={handleVolume}
        onOpenSubtitles={() => setSubtitleOpen(true)}
      />

      <SubtitleDialog
        open={subtitleOpen}
        title={state?.title || state?.item?.title || 'Subtitle Search'}
        mediaKind={(state?.media_kind === 'tv' ? 'show' : 'movie')}
        year={state?.year ?? state?.item?.year ?? undefined}
        season={state?.season ?? undefined}
        episode={state?.episode ?? undefined}
        onClose={() => setSubtitleOpen(false)}
      />
    </div>
  )
}
