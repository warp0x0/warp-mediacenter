import { useEffect, useMemo, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { usePlayerStatus, playMedia, pausePlayback, resumePlayback, stopPlayback, seekPlayback, setVolume } from '@/hooks/usePlayer'
import PlaybackControls from '@/components/media/PlaybackControls'
import SubtitleDialog from '@/components/media/SubtitleDialog'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import type { MediaItem, PlayerPlayRequest } from '@/lib/types'

type PlaybackLocationState = PlayerPlayRequest & {
  item?: MediaItem
  sourceType?: string
  isStream?: boolean
}

export default function PlaybackPage() {
  const location = useLocation()
  const navigate = useNavigate()
  const state = location.state as PlaybackLocationState | null
  const { data: status, mutate } = usePlayerStatus()
  const [subtitleOpen, setSubtitleOpen] = useState(false)
  const [started, setStarted] = useState(false)

  const playRequest = useMemo<PlayerPlayRequest | null>(() => {
    if (!state?.source) return null
    return {
      source: state.source,
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

  useEffect(() => {
    if (!playRequest || started) return
    let mounted = true
    playMedia(playRequest)
      .then(() => {
        if (mounted) {
          setStarted(true)
          mutate()
        }
      })
      .catch(() => {
        if (mounted) setStarted(true)
      })
    return () => {
      mounted = false
    }
  }, [playRequest, started, mutate])

  async function handleTogglePlayPause() {
    if (status?.playing) {
      await pausePlayback()
    } else {
      await resumePlayback()
    }
    mutate()
  }

  async function handleStop() {
    await stopPlayback()
    navigate(-1)
  }

  async function handleSeek(positionMs: number) {
    await seekPlayback(positionMs)
    mutate()
  }

  async function handleVolume(volume: number) {
    await setVolume(volume)
    mutate()
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
