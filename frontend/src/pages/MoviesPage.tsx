import { useMemo } from 'react'
import { useCatalog } from '@/hooks/useCatalog'
import { useWidgets } from '@/hooks/useSettings'
import { DEFAULT_MOVIE_WIDGETS } from '@/lib/constants'
import WidgetSection from '@/components/media/WidgetSection'

export default function MoviesPage() {
  const { data: widgetsData } = useWidgets()

  // Merge saved config with defaults — always exactly 6 slots
  const w = widgetsData?.movies ?? DEFAULT_MOVIE_WIDGETS

  // Each hook must be called unconditionally (rules of hooks).
  // The SWR key re-derives when the widget config loads, triggering re-fetches.
  const r0 = useCatalog(w[0]?.provider ?? 'tmdb', w[0]?.category ?? 'trending_day',  'movie')
  const r1 = useCatalog(w[1]?.provider ?? 'tmdb', w[1]?.category ?? 'popular',       'movie')
  const r2 = useCatalog(w[2]?.provider ?? 'tmdb', w[2]?.category ?? 'top_rated',     'movie')
  const r3 = useCatalog(w[3]?.provider ?? 'tmdb', w[3]?.category ?? 'now_playing',   'movie')
  const r4 = useCatalog(w[4]?.provider ?? 'tmdb', w[4]?.category ?? 'upcoming',      'movie')
  const r5 = useCatalog(w[5]?.provider ?? 'tmdb', w[5]?.category ?? 'trending_week', 'movie')

  const catalogResults = [
    { title: w[0]?.title ?? 'Widget 1', ...r0 },
    { title: w[1]?.title ?? 'Widget 2', ...r1 },
    { title: w[2]?.title ?? 'Widget 3', ...r2 },
    { title: w[3]?.title ?? 'Widget 4', ...r3 },
    { title: w[4]?.title ?? 'Widget 5', ...r4 },
    { title: w[5]?.title ?? 'Widget 6', ...r5 },
  ]

  const isLoading = useMemo(
    () => catalogResults.some((r) => r.isLoading),
    [catalogResults],
  )

  return (
    <div
      data-nav-scroll-container
      className="h-full w-full overflow-y-auto overflow-x-hidden scrollbar-hidden"
      style={{
        scrollSnapType: 'y mandatory',
      }}
    >
      {catalogResults.map(({ title, data }, idx) => (
        <WidgetSection
          key={title}
          title={title}
          items={data?.items ?? []}
          isLoading={isLoading}
          mediaType="movie"
          provider={w[idx]?.provider}
          category={w[idx]?.category}
          initialFocus={idx === 0}
        />
      ))}
    </div>
  )
}
