import { useEffect, useRef } from 'react'
import { getPendingPlayback, isTauriRuntime, listenNativePlayerStatus } from '@/lib/tauri'
import { scrobbleStart, scrobbleStop, stopPreloadSession } from '@/hooks/usePlayer'
import type { NativePlayerStatusResponse, PendingPlayback, PlayerScrobbleRequest } from '@/lib/types'

function buildScrobbleContext(pb: PendingPlayback): PlayerScrobbleRequest | null {
  const mediaType = pb.media_kind === 'tv' ? 'episode' : 'movie'
  const tmdbId = pb.tmdb_id ? Number(pb.tmdb_id) : null
  const traktId = pb.trakt_id ? Number(pb.trakt_id) : null
  const ids = {
    ...(tmdbId ? { tmdb: tmdbId } : {}),
    ...(traktId ? { trakt: traktId } : {}),
  }

  if (mediaType === 'episode') {
    // Trakt episode scrobble: identify the episode by season+number,
    // and the show by its title/year/ids (tmdb/trakt are show-level IDs).
    return {
      session_id: pb.session_id ?? null,
      media_type: 'episode',
      media: {
        season: pb.season ?? 1,
        number: pb.episode ?? 1,
      },
      show: { title: pb.title, year: pb.year ?? undefined, ids },
      progress: 0,
    }
  }

  // Movie: identify by title/year/ids
  return {
    session_id: pb.session_id ?? null,
    media_type: 'movie',
    media: { title: pb.title, year: pb.year ?? undefined, ids },
    show: undefined,
    progress: 0,
  }
}

export function usePlaybackScrobble() {
  const playbackRef = useRef<PendingPlayback | null>(null)
  const scrobbleStartedRef = useRef(false)
  const scrobbleStopSentRef = useRef(false)
  const activeSessionIdRef = useRef<string | null>(null)

  useEffect(() => {
    if (!isTauriRuntime()) return

    let unlisten: (() => void) | null = null

    const handleStatus = async (status: NativePlayerStatusResponse) => {
      const sessionId = status.session_id ?? null

      // Detect new session: session_id changed while we had an active one
      if (sessionId && sessionId !== activeSessionIdRef.current) {
        // Fire stop for the previous session if it was in progress
        if (scrobbleStartedRef.current && !scrobbleStopSentRef.current && playbackRef.current) {
          scrobbleStopSentRef.current = true
          const ctx = buildScrobbleContext(playbackRef.current)
          if (ctx) void scrobbleStop({ ...ctx, progress: 0 })
        }
        // Reset for new session
        playbackRef.current = null
        scrobbleStartedRef.current = false
        scrobbleStopSentRef.current = false
        activeSessionIdRef.current = sessionId
      }

      // Error state: file failed to load (bad format, network error, etc.).
      // Reset refs so the next successful file starts with a clean slate.
      // Do NOT fire scrobbleStop — no playback ever started.
      if (status.state === 'error') {
        playbackRef.current = null
        scrobbleStartedRef.current = false
        scrobbleStopSentRef.current = false
        return
      }

      if (status.state === 'playing') {
        // Fetch playback metadata the first time we see a playing state
        if (!playbackRef.current) {
          try {
            const pb = await getPendingPlayback()
            if (pb) {
              playbackRef.current = pb
              activeSessionIdRef.current = pb.session_id ?? null
            }
          } catch {
            // best effort
          }
        }

        if (!scrobbleStartedRef.current && playbackRef.current) {
          scrobbleStartedRef.current = true
          const ctx = buildScrobbleContext(playbackRef.current)
          if (ctx) void scrobbleStart({ ...ctx, progress: 0 })
        }
      }

      if (status.state === 'ended' || status.state === 'stopped') {
        if (scrobbleStartedRef.current && !scrobbleStopSentRef.current) {
          scrobbleStopSentRef.current = true
          const pb = playbackRef.current
          if (pb) {
            const ctx = buildScrobbleContext(pb)
            const progress =
              status.duration_ms > 0 ? (status.position_ms / status.duration_ms) * 100 : 100
            if (ctx) void scrobbleStop({ ...ctx, progress })
            if (pb.session_id) void stopPreloadSession(pb.session_id).catch(() => {})
          }
        }
        // Reset ALL refs so the next session starts clean.
        playbackRef.current = null
        activeSessionIdRef.current = null
        scrobbleStartedRef.current = false
        scrobbleStopSentRef.current = false
      }

      // Idle state: fire scrobbleStop if scrobble was started but stop not yet sent,
      // then reset for the next session.
      if (status.state === 'idle') {
        if (scrobbleStartedRef.current && !scrobbleStopSentRef.current) {
          scrobbleStopSentRef.current = true
          const pb = playbackRef.current
          if (pb) {
            const ctx = buildScrobbleContext(pb)
            if (ctx) void scrobbleStop({ ...ctx, progress: 0 })
          }
        }
        playbackRef.current = null
        activeSessionIdRef.current = null
        scrobbleStartedRef.current = false
        scrobbleStopSentRef.current = false
      }
    }

    listenNativePlayerStatus(handleStatus).then((fn) => {
      unlisten = fn
    })

    return () => {
      unlisten?.()
    }
  }, [])
}
