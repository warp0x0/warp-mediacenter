import { NavLink } from 'react-router-dom'
import { Search, Film, Tv, HardDrive, Settings, Power } from 'lucide-react'

const tabs = [
  { to: '/search', icon: Search, label: 'Search' },
  { to: '/', icon: Film, label: 'Movies', end: true },
  { to: '/shows', icon: Tv, label: 'Shows' },
  { to: '/local', icon: HardDrive, label: 'Local Drive' },
  { to: '/settings', icon: Settings, label: 'Settings' },
  { to: '/power', icon: Power, label: 'Power' },
]

export default function Sidebar() {
  return (
    <nav
      className="flex flex-col bg-bg-sidebar backdrop-blur-xl border-r border-white/5 pt-[clamp(8px,0.83vw,16px)] pb-[clamp(8px,0.83vw,16px)] gap-[clamp(2px,0.16vw,4px)]"
      style={{ width: 'var(--sidebar-width)' }}
    >
      {tabs.map(({ to, icon: Icon, label, end }) => (
        <NavLink
          key={to}
          to={to}
          end={end}
          className={({ isActive }) =>
            `flex items-center gap-[clamp(8px,0.63vw,14px)] mx-[clamp(4px,0.31vw,8px)] px-[clamp(10px,0.73vw,16px)] rounded-btn text-body font-medium transition-colors cursor-pointer ${
              isActive
                ? 'bg-accent-muted text-accent border-l-[3px] border-accent'
                : 'text-fg-primary hover:bg-white/6'
            }`
          }
          style={{ height: 'clamp(36px, 4.07vh, 48px)' }}
        >
          <Icon size={clampIcon()} />
          <span>{label}</span>
        </NavLink>
      ))}
    </nav>
  )
}

function clampIcon(): number {
  return typeof window !== 'undefined'
    ? Math.round(Math.min(Math.max(16, window.innerWidth * 0.0104), 22))
    : 20
}
