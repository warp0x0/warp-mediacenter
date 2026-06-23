import { useState } from 'react'
import type { LucideIcon } from 'lucide-react'
import {
  ShieldCheck, Zap, Key, Server, Grid, Sliders, Settings,
} from 'lucide-react'
import { useProviders } from '@/hooks/useSettings'
import SettingsCard from '@/components/settings/SettingsCard'
import AuthPanel from '@/components/settings/AuthPanel'
import ProviderStatusRow from '@/components/settings/ProviderStatusRow'
import ApiKeysForm from '@/components/settings/ApiKeysForm'
import ServerConnection from '@/components/settings/ServerConnection'
import CatalogConfigPanel from '@/components/settings/CatalogConfigPanel'
import GeneralSettings from '@/components/settings/GeneralSettings'

interface Section {
  id: string
  icon: LucideIcon
  label: string
  description: string
}

const sections: Section[] = [
  { id: 'auth',      icon: ShieldCheck, label: 'Authentication', description: 'Trakt & Real Debrid accounts' },
  { id: 'providers', icon: Zap,         label: 'Providers',      description: 'Service connection status'    },
  { id: 'keys',      icon: Key,         label: 'API Keys',       description: 'TMDb and provider keys'       },
  { id: 'server',    icon: Server,      label: 'Connection',     description: 'Backend server settings'      },
  { id: 'catalog',   icon: Grid,        label: 'Catalog',        description: 'Content sources & widgets'    },
  { id: 'general',   icon: Sliders,     label: 'General',        description: 'App preferences'              },
]

export default function SettingsPage() {
  const [activeSection, setActiveSection] = useState('auth')
  const { data: providers, isLoading: providersLoading } = useProviders()
  const active = sections.find(s => s.id === activeSection)!
  const ActiveIcon = active.icon

  return (
    <div
      className="flex w-full overflow-hidden bg-bg-primary"
      style={{ height: '100vh', paddingTop: 'var(--tabbar-height)' }}
    >

      {/* ── LEFT SIDEBAR ── */}
      <aside
        className="flex flex-col shrink-0 border-r border-white/[0.07] overflow-hidden"
        style={{
          width: 'clamp(220px, 15vw, 280px)',
          background: 'linear-gradient(180deg, rgba(0,0,0,0.75) 0%, rgba(8,8,14,0.92) 100%)',
          backdropFilter: 'blur(24px)',
          WebkitBackdropFilter: 'blur(24px)',
        }}
      >
        {/* Sidebar header */}
        <div
          className="flex items-center gap-3 shrink-0 border-b border-white/[0.07]"
          style={{ padding: 'clamp(14px,1.5vh,22px) clamp(16px,1.2vw,22px)' }}
        >
          <div
            className="flex items-center justify-center rounded-lg bg-accent/20 text-accent shrink-0"
            style={{ width: 'clamp(32px,2.1vw,40px)', height: 'clamp(32px,2.1vw,40px)' }}
          >
            <Settings size={15} />
          </div>
          <div>
            <p
              className="text-white font-bold uppercase tracking-[0.14em]"
              style={{ fontSize: 'clamp(11px,0.65vw,13px)' }}
            >
              Settings
            </p>
            <p className="text-white/30" style={{ fontSize: 'clamp(9px,0.55vw,11px)' }}>
              Warp Media Center
            </p>
          </div>
        </div>

        {/* Nav items */}
        <nav className="flex flex-col flex-1 overflow-y-auto scrollbar-hidden py-2">
          {sections.map(({ id, icon: Icon, label, description }) => {
            const isActive = id === activeSection
            return (
              <button
                key={id}
                data-nav-item
                data-nav-id={`settings-section:${id}`}
                data-nav-kind="tab"
                data-nav-axis="vertical"
                data-nav-group="settings-sidebar"
                onClick={() => setActiveSection(id)}
                {...(id === 'auth' ? { 'data-nav-initial': '' } : {})}
                className="group relative flex items-center gap-3 w-full text-left transition-all duration-200 cursor-pointer"
                style={{ padding: 'clamp(9px,1vh,14px) clamp(14px,1.1vw,20px)' }}
              >
                {/* Left accent bar */}
                {isActive && (
                  <span
                    className="absolute left-0 rounded-r-full bg-accent"
                    style={{ width: '3px', top: '18%', bottom: '18%' }}
                  />
                )}

                {/* Icon box */}
                <div
                  className={`flex items-center justify-center rounded-lg shrink-0 transition-all duration-200 ${
                    isActive
                      ? 'bg-accent/25 text-accent shadow-[0_0_14px_rgba(13,178,226,0.22)]'
                      : 'bg-white/[0.05] text-white/40 group-hover:bg-white/[0.09] group-hover:text-white/65'
                  }`}
                  style={{ width: 'clamp(34px,2.2vw,42px)', height: 'clamp(34px,2.2vw,42px)' }}
                >
                  <Icon size={16} />
                </div>

                {/* Label + description */}
                <div className="min-w-0 flex-1">
                  <p
                    className={`font-semibold truncate transition-colors duration-200 ${
                      isActive ? 'text-accent' : 'text-white/55 group-hover:text-white/80'
                    }`}
                    style={{ fontSize: 'clamp(13px,0.83vw,15px)' }}
                  >
                    {label}
                  </p>
                  <p className="text-white/25 truncate" style={{ fontSize: 'clamp(10px,0.55vw,11px)' }}>
                    {description}
                  </p>
                </div>
              </button>
            )
          })}
        </nav>

        {/* Footer */}
        <div
          className="shrink-0 border-t border-white/[0.07]"
          style={{ padding: 'clamp(10px,1vh,14px) clamp(14px,1.1vw,20px)' }}
        >
          <p className="text-white/20 uppercase tracking-widest" style={{ fontSize: '9px' }}>
            v1.0.0 · Warp Media Center
          </p>
        </div>
      </aside>

      {/* ── CONTENT PANEL ── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">

        {/* Content header */}
        <div
          className="flex items-center gap-4 shrink-0 border-b border-white/[0.07]"
          style={{
            padding: 'clamp(14px,1.5vh,20px) clamp(20px,1.67vw,32px)',
            background: 'rgba(255,255,255,0.02)',
          }}
        >
          <div
            className="flex items-center justify-center rounded-xl bg-accent/20 text-accent shrink-0"
            style={{ width: 'clamp(38px,2.5vw,48px)', height: 'clamp(38px,2.5vw,48px)' }}
          >
            <ActiveIcon size={18} />
          </div>
          <div>
            <h2 className="text-white font-bold" style={{ fontSize: 'clamp(15px,1.1vw,20px)' }}>
              {active.label}
            </h2>
            <p className="text-white/35" style={{ fontSize: 'clamp(11px,0.65vw,13px)' }}>
              {active.description}
            </p>
          </div>
        </div>

        {/* Scrollable content body */}
        <div
          data-nav-scroll-container
          className="flex-1 overflow-y-auto"
          style={{ padding: 'clamp(16px,1.67vw,28px)' }}
        >
          {activeSection === 'auth' && (
            <SettingsCard icon={<ShieldCheck />} title="Authentication">
              <AuthPanel type="trakt" />
              <div className="border-t border-white/5" />
              <AuthPanel type="debrid" />
            </SettingsCard>
          )}

          {activeSection === 'providers' && (
            <SettingsCard icon={<Zap />} title="Provider Status">
              {providersLoading ? (
                <p className="text-fg-muted" style={{ fontSize: 'var(--subtitle-size)' }}>Loading…</p>
              ) : (
                <>
                  <ProviderStatusRow name="TMDb"        status={providers?.tmdb}         isLoading={providersLoading} />
                  <ProviderStatusRow name="Trakt"       status={providers?.trakt}        isLoading={providersLoading} />
                  <ProviderStatusRow name="Real Debrid" status={providers?.realdebrid}   isLoading={providersLoading} />
                  <ProviderStatusRow name="Torrent API" status={providers?.torrent_api}  isLoading={providersLoading} />
                </>
              )}
            </SettingsCard>
          )}

          {activeSection === 'keys' && (
            <SettingsCard icon={<Key />} title="API Keys">
              <ApiKeysForm />
            </SettingsCard>
          )}

          {activeSection === 'server' && (
            <SettingsCard icon={<Server />} title="Server Connection">
              <ServerConnection />
            </SettingsCard>
          )}

          {activeSection === 'catalog' && (
            <SettingsCard icon={<Grid />} title="Catalog Configuration">
              <CatalogConfigPanel />
            </SettingsCard>
          )}

          {activeSection === 'general' && (
            <SettingsCard icon={<Sliders />} title="General Settings">
              <GeneralSettings />
            </SettingsCard>
          )}
        </div>
      </div>
    </div>
  )
}
