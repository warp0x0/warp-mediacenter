import { useEffect, useState } from 'react'
import type { ReactNode } from 'react'
import { Server, Globe, Terminal, ExternalLink, Trash2, Power as PowerIcon } from 'lucide-react'
import { useHealth } from '@/hooks/useSettings'
import SettingsCard from '@/components/settings/SettingsCard'

function useUptime() {
  const [uptime, setUptime] = useState(0)
  useEffect(() => {
    const start = Date.now()
    const timer = setInterval(() => setUptime(Date.now() - start), 1000)
    return () => clearInterval(timer)
  }, [])
  const total = Math.floor(uptime / 1000)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = total % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

export default function PowerPage() {
  const { data: health, isLoading } = useHealth()
  const uptime = useUptime()
  const [confirmQuit, setConfirmQuit] = useState(false)

  const serverUrl    = 'http://localhost:8000'
  const torrentUrl   = 'http://localhost:8009'

  const isOnline    = !isLoading && health?.status === 'ok'
  const statusLabel = isLoading ? 'Checking…' : health ? (health.status === 'ok' ? 'Running' : 'Degraded') : 'Disconnected'
  const dotColor    = isLoading ? 'bg-white/30' : isOnline ? 'bg-success' : health ? 'bg-warning' : 'bg-danger'
  const statusColor = isLoading ? 'text-white/40' : isOnline ? 'text-success' : health ? 'text-warning' : 'text-danger'

  function handleQuit() {
    if (confirmQuit) {
      try { window.close() } catch { /* Tauri exit */ }
    } else {
      setConfirmQuit(true)
    }
  }

  return (
    <div
      data-nav-scroll-container
      className="w-full overflow-y-auto bg-bg-primary"
      style={{ height: '100vh', paddingTop: 'var(--tabbar-height)' }}
    >
      <div
        className="flex flex-col w-full"
        style={{
          padding: 'clamp(20px, 2.5vh, 36px) clamp(24px, 2.5vw, 48px)',
          gap: 'clamp(16px, 2vh, 24px)',
        }}
      >

        {/* ── SYSTEM HERO CARD ── */}
        <div
          className="rounded-card border border-white/[0.07] overflow-hidden"
          style={{ background: 'rgba(255,255,255,0.025)' }}
        >
          {/* Accent top stripe */}
          <div
            className="h-[3px] w-full"
            style={{ background: 'linear-gradient(90deg, var(--accent) 0%, rgba(13,178,226,0.15) 100%)' }}
          />

          <div
            className="flex items-center justify-between flex-wrap"
            style={{ padding: 'clamp(18px,2vh,28px) clamp(20px,1.67vw,32px)', gap: 'clamp(12px,1vw,20px)' }}
          >
            {/* App identity */}
            <div className="flex items-center gap-4">
              <div
                className="flex items-center justify-center rounded-xl bg-accent/20 text-accent shrink-0"
                style={{ width: 'clamp(44px,3vw,56px)', height: 'clamp(44px,3vw,56px)' }}
              >
                <PowerIcon size={22} />
              </div>
              <div>
                <p className="text-white font-bold" style={{ fontSize: 'clamp(16px,1.2vw,22px)' }}>
                  Warp Media Center
                </p>
                <p className="text-white/30 font-mono" style={{ fontSize: 'clamp(10px,0.6vw,12px)', marginTop: '2px' }}>
                  v0.0.1 · Power & System
                </p>
              </div>
            </div>

            {/* Live status + uptime */}
            <div className="flex items-center" style={{ gap: 'clamp(16px,1.5vw,28px)' }}>
              {/* Server health */}
              <div className="text-right">
                <div className="flex items-center justify-end gap-2">
                  <div className={`w-2 h-2 rounded-full ${dotColor} ${isOnline ? 'animate-pulse' : ''}`} />
                  <span className={`font-semibold ${statusColor}`} style={{ fontSize: 'clamp(12px,0.75vw,14px)' }}>
                    {statusLabel}
                  </span>
                </div>
                <p className="text-white/25" style={{ fontSize: 'clamp(9px,0.52vw,11px)', marginTop: '2px' }}>
                  API Server
                </p>
              </div>

              {/* Divider */}
              <div className="self-stretch border-l border-white/[0.07]" />

              {/* Uptime clock */}
              <div className="text-right">
                <p
                  className="font-mono text-white/85 font-bold tabular-nums"
                  style={{ fontSize: 'clamp(18px,1.5vw,26px)', letterSpacing: '0.04em' }}
                >
                  {uptime}
                </p>
                <p className="text-white/25" style={{ fontSize: 'clamp(9px,0.52vw,11px)', marginTop: '2px' }}>
                  Session uptime
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* ── SERVER STATUS + SYSTEM INFO (auto 2-col on wide) ── */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: 'clamp(12px,1.5vw,20px)',
          }}
        >
          {/* Server status */}
          <SettingsCard icon={<Server />} title="Server Status">
            <StatusRow
              label="API Server"
              sublabel={serverUrl}
              dotClass={`${dotColor} ${isOnline ? 'animate-pulse' : ''}`}
              statusText={statusLabel}
              statusClass={statusColor}
            />
            <div className="border-t border-white/[0.05]" />
            <StatusRow
              label="Torrent-API-Py"
              sublabel="Sub-process"
              dotClass="bg-white/25"
              statusText="Server-managed"
              statusClass="text-white/35"
            />
          </SettingsCard>

          {/* System info */}
          <SettingsCard icon={<Globe />} title="System Information">
            {[
              { label: 'API Server',     value: serverUrl    },
              { label: 'Torrent-API-Py', value: torrentUrl   },
              { label: 'Application',    value: 'Warp v0.0.1'},
              { label: 'Session uptime', value: uptime       },
            ].map(({ label, value }) => (
              <div key={label} className="flex items-center justify-between" style={{ gap: '12px' }}>
                <span className="text-white/38 shrink-0" style={{ fontSize: 'clamp(11px,0.65vw,13px)' }}>
                  {label}
                </span>
                <span className="text-white/70 font-mono truncate" style={{ fontSize: 'clamp(11px,0.65vw,13px)' }}>
                  {value}
                </span>
              </div>
            ))}
          </SettingsCard>
        </div>

        {/* ── ACTIONS ── */}
        <SettingsCard icon={<Terminal />} title="Actions">
          <div className="flex flex-wrap" style={{ gap: 'clamp(8px,0.8vw,12px)' }}>
            <ActionBtn
              icon={<ExternalLink size={14} />}
              label="Open API Docs"
              onClick={() => window.open(`${serverUrl}/docs`, '_blank')}
            />
            <ActionBtn
              icon={<Trash2 size={14} />}
              label="Clear Cache"
              onClick={() => { try { localStorage.clear() } catch { /* noop */ } }}
            />
            <ActionBtn
              icon={<PowerIcon size={14} />}
              label={confirmQuit ? 'Confirm Quit' : 'Quit App'}
              onClick={handleQuit}
              variant={confirmQuit ? 'danger' : 'default'}
            />
            {confirmQuit && (
              <ActionBtn label="Cancel" onClick={() => setConfirmQuit(false)} />
            )}
          </div>
        </SettingsCard>

      </div>
    </div>
  )
}

// ── Helpers ────────────────────────────────────────────────────────────────

interface StatusRowProps {
  label: string
  sublabel: string
  dotClass: string
  statusText: string
  statusClass: string
}

function StatusRow({ label, sublabel, dotClass, statusText, statusClass }: StatusRowProps) {
  return (
    <div className="flex items-center justify-between" style={{ gap: '12px' }}>
      <div className="flex items-center" style={{ gap: 'clamp(8px,0.6vw,12px)' }}>
        <div className={`w-[7px] h-[7px] rounded-full shrink-0 ${dotClass}`} />
        <div>
          <p className="text-white/72 font-medium" style={{ fontSize: 'clamp(12px,0.75vw,14px)' }}>
            {label}
          </p>
          <p className="text-white/25" style={{ fontSize: 'clamp(10px,0.55vw,11px)' }}>
            {sublabel}
          </p>
        </div>
      </div>
      <span className={`font-medium shrink-0 ${statusClass}`} style={{ fontSize: 'clamp(11px,0.65vw,13px)' }}>
        {statusText}
      </span>
    </div>
  )
}

interface ActionBtnProps {
  icon?: ReactNode
  label: string
  onClick: () => void
  variant?: 'default' | 'danger'
}

function ActionBtn({ icon, label, onClick, variant = 'default' }: ActionBtnProps) {
  const isDanger = variant === 'danger'
  return (
    <button
      data-nav-item
      data-nav-id={`power:action:${label.replace(/[^a-zA-Z0-9:_-]+/g, '-')}`}
      data-nav-kind="button"
      data-nav-axis="horizontal"
      data-nav-group="power-actions"
      onClick={onClick}
      className={`flex items-center rounded-btn font-medium cursor-pointer transition-all duration-200 ${
        isDanger
          ? 'bg-danger/15 text-danger border border-danger/30 hover:bg-danger/25'
          : 'bg-white/[0.06] text-white/60 border border-white/[0.08] hover:bg-white/[0.11] hover:text-white/85'
      }`}
      style={{
        gap: 'clamp(5px,0.4vw,8px)',
        padding: 'clamp(8px,0.75vh,12px) clamp(14px,1.1vw,22px)',
        fontSize: 'clamp(12px,0.75vw,14px)',
      }}
    >
      {icon}
      {label}
    </button>
  )
}
