import { useMemo, useEffect, useRef } from 'react'
import { useCatalog } from '@/hooks/useCatalog'
import { useWidgets } from '@/hooks/useSettings'
import { DEFAULT_SHOW_WIDGETS } from '@/lib/constants'
import WidgetSection from '@/components/media/WidgetSection'

export default function ShowsPage() {
  const containerRef = useRef<HTMLDivElement>(null)
  const { data: widgetsData } = useWidgets()

  // Merge saved config with defaults — always exactly 6 slots
  const w = widgetsData?.shows ?? DEFAULT_SHOW_WIDGETS

  // Each hook must be called unconditionally (rules of hooks).
  // The SWR key re-derives when the widget config loads, triggering re-fetches.
  const r0 = useCatalog(w[0]?.provider ?? 'tmdb', w[0]?.category ?? 'trending_day',  'show')
  const r1 = useCatalog(w[1]?.provider ?? 'tmdb', w[1]?.category ?? 'popular',       'show')
  const r2 = useCatalog(w[2]?.provider ?? 'tmdb', w[2]?.category ?? 'top_rated',     'show')
  const r3 = useCatalog(w[3]?.provider ?? 'tmdb', w[3]?.category ?? 'airing_today',  'show')
  const r4 = useCatalog(w[4]?.provider ?? 'tmdb', w[4]?.category ?? 'on_the_air',    'show')
  const r5 = useCatalog(w[5]?.provider ?? 'tmdb', w[5]?.category ?? 'trending_week', 'show')

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

  useEffect(() => {
    const el = containerRef.current
    if (el) {
      el.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }, [isLoading])

  return (
    <div
      ref={containerRef}
      className="h-full w-full overflow-y-auto overflow-x-hidden scrollbar-hidden"
      style={{
        scrollSnapType: 'y mandatory',
        scrollBehavior: 'smooth',
      }}
    >
      {catalogResults.map(({ title, data }) => (
        <WidgetSection
          key={title}
          title={title}
          items={data?.items ?? []}
          isLoading={isLoading}
          mediaType="show"
        />
      ))}
    </div>
  )
}
