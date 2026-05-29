import { useState, useMemo, useEffect } from 'react'
import { useParams, useNavigate, useLocation } from 'react-router-dom'
import { useTitleEpisodes } from '@/hooks/useLibrary'
import { useShowSeasons } from '@/hooks/useDetail'
import EpisodeGrid from '@/components/media/EpisodeGrid'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import type { MediaItem, TitleEpisode, EpisodeDetail } from '@/lib/types'
import type { EpisodeCardData } from '@/components/cards/EpisodeCard'

type LocationState = { item?: MediaItem }

function episodeToCard(ep: TitleEpisode): EpisodeCardData {
  return {
    id: ep.id,
    season: ep.season,
    episode: ep.episode,
    name: ep.name,
    air_date: ep.air_date,
    has_source: false,
  }
}

function tmdbEpisodeToCard(ep: EpisodeDetail): EpisodeCardData {
  return {
    id: typeof ep.id === 'string' ? parseInt(ep.id, 10) || 0 : 0,
    season: ep.season_number ?? 0,
    episode: ep.episode_number ?? 0,
    name: ep.title || null,
    air_date: ep.air_date ?? null,
    has_source: false,
  }
}

export default function EpisodeGridPage() {
  const { showId } = useParams<{ showId: string }>()
  const location = useLocation()
  const navigate = useNavigate()
  const state = location.state as LocationState | null
  const [selectedSeason, setSelectedSeason] = useState(1)

  const localQuery = useTitleEpisodes(showId ?? null, selectedSeason)
  const tmdbQuery = useShowSeasons(showId ?? null)

  const useLocal = localQuery.data && localQuery.data.episodes.length > 0

  const allSeasons = useMemo(() => {
    if (useLocal && localQuery.data) {
      const seasons = new Set<number>()
      localQuery.data.episodes.forEach((ep) => seasons.add(ep.season))
      return Array.from(seasons).sort((a, b) => a - b)
    }
    if (tmdbQuery.data) {
      return tmdbQuery.data.seasons
        .filter((s) => s.episodes && s.episodes.length > 0)
        .map((s) => s.season_number)
        .sort((a, b) => a - b)
    }
    return [selectedSeason]
  }, [useLocal, localQuery.data, tmdbQuery.data, selectedSeason])

  const cards = useMemo<EpisodeCardData[]>(() => {
    if (useLocal && localQuery.data) {
      return localQuery.data.episodes.map(episodeToCard)
    }
    if (tmdbQuery.data) {
      const season = tmdbQuery.data.seasons.find((s) => s.season_number === selectedSeason)
      return (season?.episodes ?? []).map(tmdbEpisodeToCard)
    }
    return []
  }, [useLocal, localQuery.data, tmdbQuery.data, selectedSeason])

  const title = state?.item?.title || localQuery.data?.title || tmdbQuery.data?.title || showId || 'Episodes'

  useEffect(() => {
    if (!useLocal && tmdbQuery.data && allSeasons.length > 0 && !allSeasons.includes(selectedSeason)) {
      setSelectedSeason(allSeasons[0])
    }
  }, [useLocal, tmdbQuery.data, allSeasons, selectedSeason])

  function handleGoBack() {
    navigate('/shows')
  }

  function handleEpisodeSelect(_ep: EpisodeCardData) {}

  function handleEpisodePlay(_ep: EpisodeCardData) {}

  const isLoading = localQuery.isLoading || (tmdbQuery.isLoading && !useLocal)

  if (isLoading) {
    return <LoadingSpinner />
  }

  if (localQuery.error && !tmdbQuery.data) {
    return (
      <div className="flex flex-col items-center justify-center p-[clamp(16px,2vh,40px)]">
        <p className="text-danger text-body mb-[clamp(8px,0.83vw,16px)]">
          Failed to load episodes.
        </p>
        <button onClick={handleGoBack} className="btn-secondary cursor-pointer">
          &larr; Back to Shows
        </button>
      </div>
    )
  }

  return (
    <div className="relative h-full overflow-y-auto">
      <div className="flex items-center justify-between px-[clamp(8px,0.83vw,16px)] pt-[clamp(8px,0.83vw,16px)] pb-[clamp(4px,0.31vw,8px)]">
        <h1
          className="font-extrabold text-fg-white tracking-tight"
          style={{ fontSize: 'var(--page-title-size)' }}
        >
          {title}
        </h1>
      </div>

      <EpisodeGrid
        episodes={cards}
        allSeasons={allSeasons}
        selectedSeason={selectedSeason}
        onSeasonChange={setSelectedSeason}
        onEpisodeSelect={handleEpisodeSelect}
        onEpisodePlay={handleEpisodePlay}
        onBack={handleGoBack}
      />
    </div>
  )
}
