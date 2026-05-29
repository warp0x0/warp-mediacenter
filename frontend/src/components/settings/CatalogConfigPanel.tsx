import { useState, useEffect } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { Settings2, X, Check, Loader2, RefreshCw, Save } from 'lucide-react'
import {
  TMDB_MOVIE_CATALOGS,
  TMDB_SHOW_CATALOGS,
  CATALOG_GROUP_LABELS,
  DEFAULT_MOVIE_WIDGETS,
  DEFAULT_SHOW_WIDGETS,
  TRAKT_MOVIE_CATALOGS,
  TRAKT_SHOW_CATALOGS,
} from '@/lib/constants'
import type { CatalogGroup } from '@/lib/constants'
import { useWidgets, saveWidgets } from '@/hooks/useSettings'
import type { WidgetConfig } from '@/lib/types'

// ---------------------------------------------------------------------------
// Configure-widget dialog
// Renders a scrollable, grouped grid of all available TMDb catalogs.
// ---------------------------------------------------------------------------

const GROUP_ORDER: CatalogGroup[] = ['standard', 'discover', 'genre', 'decade']

interface ConfigureDialogProps {
  widgetIndex: number
  mediaType: 'movies' | 'shows'
  current: WidgetConfig
  onSelect: (config: WidgetConfig) => void
  onClose: () => void
}

function ConfigureDialog({
  widgetIndex,
  mediaType,
  current,
  onSelect,
  onClose,
}: ConfigureDialogProps) {
  const [providerTab, setProviderTab] = useState<'tmdb' | 'trakt'>('tmdb')
  const allCatalogs = mediaType === 'movies' ? TMDB_MOVIE_CATALOGS : TMDB_SHOW_CATALOGS

  // Group catalogs by their group key, preserving GROUP_ORDER
  const grouped = GROUP_ORDER.reduce<Record<CatalogGroup, typeof allCatalogs>>(
    (acc, g) => {
      acc[g] = allCatalogs.filter((c) => c.group === g)
      return acc
    },
    { standard: [], discover: [], genre: [], decade: [] },
  )

  return (
    <AnimatePresence>
      <>
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50"
          style={{
            background: 'rgba(0,0,0,0.75)',
            backdropFilter: 'blur(8px)',
            WebkitBackdropFilter: 'blur(8px)',
          }}
          onClick={onClose}
        />

        {/* Dialog */}
        <motion.div
          initial={{ opacity: 0, y: 18, scale: 0.97 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: 18, scale: 0.97 }}
          transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
          className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50 flex flex-col overflow-hidden rounded-card border border-white/[0.09]"
          style={{
            width: 'clamp(480px, 42vw, 680px)',
            maxHeight: 'min(88vh, 820px)',
            background: 'rgba(10,10,14,0.97)',
            backdropFilter: 'blur(32px)',
            WebkitBackdropFilter: 'blur(32px)',
          }}
        >
          {/* Accent stripe */}
          <div
            className="h-[3px] w-full shrink-0"
            style={{
              background:
                'linear-gradient(90deg, var(--accent) 0%, rgba(13,178,226,0.08) 100%)',
            }}
          />

          {/* ── Header ── */}
          <div
            className="flex items-center justify-between shrink-0 border-b border-white/[0.07]"
            style={{ padding: 'clamp(13px,1.3vh,18px) clamp(18px,1.4vw,26px)' }}
          >
            <div className="flex items-center gap-3">
              <div
                className="flex items-center justify-center rounded-lg shrink-0 bg-accent/15 text-accent"
                style={{
                  width: 'clamp(30px,1.9vw,38px)',
                  height: 'clamp(30px,1.9vw,38px)',
                }}
              >
                <Settings2 size={14} />
              </div>
              <div>
                <h2
                  className="text-white font-bold"
                  style={{ fontSize: 'clamp(14px,0.95vw,17px)' }}
                >
                  Configure Widget {widgetIndex + 1}
                </h2>
                <p
                  className="text-white/35"
                  style={{ fontSize: 'clamp(10px,0.58vw,12px)', marginTop: '1px' }}
                >
                  {mediaType === 'movies' ? 'Movie' : 'Show'} catalog — click any
                  source to assign it
                </p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="flex items-center justify-center rounded-lg text-white/35 hover:text-white/70 hover:bg-white/[0.07] transition-colors cursor-pointer shrink-0"
              style={{
                width: 'clamp(26px,1.7vw,32px)',
                height: 'clamp(26px,1.7vw,32px)',
              }}
            >
              <X size={13} />
            </button>
          </div>

          {/* ── Provider tabs ── */}
          <div
            className="flex justify-center gap-1 shrink-0 border-b border-white/[0.07]"
            style={{ 
              padding: 'clamp(8px,0.8vh,12px) clamp(18px,1.4vw,26px)'
            }}
          >
            {(['tmdb', 'trakt'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setProviderTab(tab)}
                className={`text-subtitle px-3 py-1 rounded-btn font-medium cursor-pointer transition-colors ${
                  providerTab === tab
                    ? 'bg-accent-muted text-accent'
                    : 'text-fg-muted hover:text-fg-primary hover:bg-white/6'
                }`}
                style={{ width: '200px', height: '40px' }}
              >
                {tab === 'tmdb' ? 'TMDb Catalogs' : 'Trakt Catalogs'}
              </button>
            ))}
          </div>

          {/* ── Scrollable catalog area ── */}
          <div
            className="flex-1 overflow-y-auto scrollbar-hidden"
            style={{ padding: 'clamp(14px,1.2vh,20px) clamp(18px,1.4vw,26px)' }}
          >
            {providerTab === 'tmdb' ? (
              <div className="flex flex-col" style={{ gap: 'clamp(14px,1.2vh,20px)' }}>
                {GROUP_ORDER.map((group) => {
                  const items = grouped[group]
                  if (!items.length) return null
                  return (
                    <div key={group}>
                      {/* Group header */}
                      <p
                        className="text-white/35 font-semibold uppercase tracking-widest mb-2"
                        style={{ fontSize: 'clamp(9px,0.53vw,10px)' }}
                      >
                        {CATALOG_GROUP_LABELS[group]}
                        <span className="ml-2 normal-case tracking-normal text-white/18">
                          ({items.length})
                        </span>
                      </p>

                      {/* 2-column catalog grid */}
                      <div
                        className="grid grid-cols-2"
                        style={{ gap: 'clamp(6px,0.5vw,10px)' }}
                      >
                        {items.map((catalog) => {
                          const isSelected =
                            current.provider === 'tmdb' &&
                            current.category === catalog.id
                          return (
                            <button
                              key={catalog.id}
                              onClick={() => {
                                onSelect({
                                  provider: 'tmdb',
                                  category: catalog.id,
                                  title: catalog.label,
                                })
                                onClose()
                              }}
                              className={`relative flex flex-col items-start gap-1 rounded-xl border cursor-pointer transition-all text-left group ${
                                isSelected
                                  ? 'border-accent/50 bg-accent/10'
                                  : 'border-white/[0.07] bg-white/[0.02] hover:border-white/18 hover:bg-white/[0.05]'
                              }`}
                              style={{ padding: 'clamp(10px,0.85vw,14px)' }}
                            >
                              {/* Selected checkmark */}
                              {isSelected && (
                                <div
                                  className="absolute top-2 right-2 flex items-center justify-center rounded-full bg-accent/20 text-accent"
                                  style={{ width: 16, height: 16 }}
                                >
                                  <Check size={9} />
                                </div>
                              )}

                              <p
                                className={`font-semibold leading-tight ${
                                  isSelected
                                    ? 'text-accent'
                                    : 'text-white/75 group-hover:text-white'
                                }`}
                                style={{ fontSize: 'clamp(11px,0.72vw,13px)' }}
                              >
                                {catalog.label}
                              </p>
                              <p
                                className="text-white/30 leading-snug"
                                style={{ fontSize: 'clamp(9px,0.55vw,10.5px)' }}
                              >
                                {catalog.description}
                              </p>
                            </button>
                          )
                        })}
                      </div>
                    </div>
                  )
                })}
              </div>
            ) : (
              /* ── Trakt catalog grid ── */
              <div className="flex flex-col" style={{ gap: 'clamp(6px,0.5vw,10px)' }}>
                <p
                  className="text-white/35 font-semibold uppercase tracking-widest mb-1"
                  style={{ fontSize: 'clamp(9px,0.53vw,10px)' }}
                >
                  Trakt Catalogs
                  <span className="ml-2 normal-case tracking-normal text-white/18">
                    ({(mediaType === 'movies' ? TRAKT_MOVIE_CATALOGS : TRAKT_SHOW_CATALOGS).length})
                  </span>
                </p>
                <div
                  className="grid grid-cols-2"
                  style={{ gap: 'clamp(6px,0.5vw,10px)' }}
                >
                  {(mediaType === 'movies' ? TRAKT_MOVIE_CATALOGS : TRAKT_SHOW_CATALOGS).map((catalog) => {
                    const isSelected =
                      current.provider === 'trakt' &&
                      current.category === catalog.id
                    return (
                      <button
                        key={catalog.id}
                        onClick={() => {
                          onSelect({
                            provider: 'trakt',
                            category: catalog.id,
                            title: catalog.label,
                          })
                          onClose()
                        }}
                        className={`relative flex flex-col items-start gap-1 rounded-xl border cursor-pointer transition-all text-left group ${
                          isSelected
                            ? 'border-accent/50 bg-accent/10'
                            : 'border-white/[0.07] bg-white/[0.02] hover:border-white/18 hover:bg-white/[0.05]'
                        }`}
                        style={{ padding: 'clamp(10px,0.85vw,14px)' }}
                      >
                        {isSelected && (
                          <div
                            className="absolute top-2 right-2 flex items-center justify-center rounded-full bg-accent/20 text-accent"
                            style={{ width: 16, height: 16 }}
                          >
                            <Check size={9} />
                          </div>
                        )}
                        <p
                          className={`font-semibold leading-tight ${
                            isSelected
                              ? 'text-accent'
                              : 'text-white/75 group-hover:text-white'
                          }`}
                          style={{ fontSize: 'clamp(11px,0.72vw,13px)' }}
                        >
                          {catalog.label}
                        </p>
                        <p
                          className="text-white/30 leading-snug"
                          style={{ fontSize: 'clamp(9px,0.55vw,10.5px)' }}
                        >
                          {catalog.description}
                        </p>
                      </button>
                    )
                  })}
                </div>
              </div>
            )}
          </div>
        </motion.div>
      </>
    </AnimatePresence>
  )
}

// ---------------------------------------------------------------------------
// Main panel
// ---------------------------------------------------------------------------

export default function CatalogConfigPanel() {
  const [mediaTab, setMediaTab] = useState<'movies' | 'shows'>('movies')
  const [configureIdx, setConfigureIdx] = useState<number | null>(null)
  const [saving, setSaving] = useState(false)
  const [savedOk, setSavedOk] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [initialized, setInitialized] = useState(false)

  const { data: widgetsData, mutate: mutateWidgets } = useWidgets()

  // Local draft — starts from defaults, syncs once when server data arrives
  const [draft, setDraft] = useState<{ movies: WidgetConfig[]; shows: WidgetConfig[] }>({
    movies: DEFAULT_MOVIE_WIDGETS,
    shows: DEFAULT_SHOW_WIDGETS,
  })

  useEffect(() => {
    if (widgetsData && !initialized) {
      setDraft({
        movies:
          widgetsData.movies.length === 6 ? widgetsData.movies : DEFAULT_MOVIE_WIDGETS,
        shows:
          widgetsData.shows.length === 6 ? widgetsData.shows : DEFAULT_SHOW_WIDGETS,
      })
      setInitialized(true)
    }
  }, [widgetsData, initialized])

  const currentWidgets = mediaTab === 'movies' ? draft.movies : draft.shows

  function handleSelectCatalog(idx: number, config: WidgetConfig) {
    setDraft((prev) => ({
      ...prev,
      [mediaTab]: prev[mediaTab].map((w, i) => (i === idx ? config : w)),
    }))
  }

  async function handleSave() {
    setSaving(true)
    setSavedOk(false)
    setSaveError(null)
    try {
      await saveWidgets(draft)
      await mutateWidgets()
      setSavedOk(true)
      setTimeout(() => setSavedOk(false), 2500)
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  function handleRefresh() {
    window.location.reload()
  }

  return (
    <>
      {/* Configure dialog — fixed positioning escapes overflow:hidden */}
      {configureIdx !== null && (
        <ConfigureDialog
          widgetIndex={configureIdx}
          mediaType={mediaTab}
          current={currentWidgets[configureIdx]}
          onSelect={(config) => handleSelectCatalog(configureIdx, config)}
          onClose={() => setConfigureIdx(null)}
        />
      )}

      <div className="flex flex-col" style={{ gap: 'clamp(14px,1.1vh,20px)' }}>

        {/* ── Movies / Shows tab switcher ── */}
        <div className="flex justify-center gap-1">
          {(['movies', 'shows'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setMediaTab(tab)}
              className={`text-subtitle px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] rounded-btn font-medium cursor-pointer transition-colors capitalize ${
                mediaTab === tab
                  ? 'bg-accent-muted text-accent'
                  : 'text-fg-muted hover:text-fg-primary hover:bg-white/6'
              }`}
              style={{ width: '100px', height: '30px' }}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* ── 6 Widget rows ── */}
        <div className="flex flex-col" style={{ gap: 'clamp(4px,0.35vh,7px)' }}>
          {currentWidgets.map((widget, idx) => (
            <div
              key={idx}
              className="flex items-center justify-between rounded-xl border border-white/[0.07] bg-white/[0.02] hover:bg-white/[0.04] transition-colors"
              style={{ padding: 'clamp(8px,0.7vh,11px) clamp(10px,0.83vw,16px)' }}
            >
              {/* Slot badge + info */}
              <div className="flex items-center" style={{ gap: 'clamp(10px,0.83vw,15px)' }}>
                <div
                  className="flex items-center justify-center shrink-0 rounded-lg bg-accent/12 text-accent font-bold"
                  style={{
                    width: 'clamp(28px,1.9vw,36px)',
                    height: 'clamp(28px,1.9vw,36px)',
                    fontSize: 'clamp(11px,0.7vw,13px)',
                  }}
                >
                  {idx + 1}
                </div>

                <div>
                  <p
                    className="text-fg-white font-medium"
                    style={{ fontSize: 'var(--body-size)' }}
                  >
                    {widget.title}
                  </p>
                  <p
                    className="text-fg-muted"
                    style={{ fontSize: 'var(--subtitle-size)' }}
                  >
                    {widget.provider === 'tmdb' ? 'TMDb' : 'Trakt'}
                    {' · '}
                    {widget.category.replace(/_/g, ' ')}
                  </p>
                </div>
              </div>

              {/* Configure button */}
              <button
                onClick={() => setConfigureIdx(idx)}
                className="flex items-center text-fg-muted hover:text-white hover:bg-white/[0.08] rounded-btn transition-colors cursor-pointer"
                style={{
                  gap: 'clamp(4px,0.3vw,6px)',
                  padding:
                    'clamp(5px,0.42vh,8px) clamp(8px,0.63vw,12px)',
                  fontSize: 'var(--subtitle-size)',
                }}
              >
                <Settings2 size={12} />
                Configure
              </button>
            </div>
          ))}
        </div>

        {/* ── Save error ── */}
        {saveError && (
          <p className="text-danger" style={{ fontSize: 'var(--subtitle-size)' }}>
            {saveError}
          </p>
        )}

        {/* ── Action buttons ── */}
        <div
          className="flex items-center"
          style={{ gap: 'clamp(6px,0.5vw,10px)', paddingTop: 'clamp(2px,0.2vh,4px)' }}
        >
          {/* Save */}
          <button
            onClick={handleSave}
            disabled={saving}
            className="flex items-center rounded-btn font-medium cursor-pointer transition-all disabled:opacity-50"
            style={{
              gap: 'clamp(5px,0.4vw,8px)',
              padding: 'clamp(7px,0.6vh,11px) clamp(12px,1vw,18px)',
              fontSize: 'var(--subtitle-size)',
              background: savedOk ? 'rgba(34,197,94,0.18)' : 'rgba(13,178,226,0.18)',
              color: savedOk ? 'rgb(74,222,128)' : 'var(--accent)',
            }}
          >
            {saving ? (
              <Loader2 size={13} className="animate-spin" />
            ) : savedOk ? (
              <Check size={13} />
            ) : (
              <Save size={13} />
            )}
            {saving ? 'Saving…' : savedOk ? 'Saved!' : 'Save'}
          </button>

          {/* Refresh Widgets */}
          <button
            onClick={handleRefresh}
            className="flex items-center text-fg-muted hover:text-white hover:bg-white/[0.08] rounded-btn transition-colors cursor-pointer"
            style={{
              gap: 'clamp(5px,0.4vw,8px)',
              padding: 'clamp(7px,0.6vh,11px) clamp(12px,1vw,18px)',
              fontSize: 'var(--subtitle-size)',
            }}
          >
            <RefreshCw size={13} />
            Refresh Widgets
          </button>
        </div>

      </div>
    </>
  )
}
