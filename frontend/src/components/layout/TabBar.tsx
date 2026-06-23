import { useNavigate, useLocation } from 'react-router-dom'
import { Search, Film, Tv, Library, Settings, Power } from 'lucide-react'

const tabs = [
  { to: '/search', icon: Search, label: 'Search' },
  { to: '/', icon: Film, label: 'Movies', end: true },
  { to: '/shows', icon: Tv, label: 'Shows' },
  { to: '/local', icon: Library, label: 'Library' },
  { to: '/settings', icon: Settings, label: 'Settings' },
  { to: '/power', icon: Power, label: 'Power' },
]

function isActiveTab(to: string, end: boolean | undefined, pathname: string): boolean {
  if (end) return pathname === to
  return pathname === to || pathname.startsWith(to + '/')
}

export default function TabBar() {
  const navigate = useNavigate()
  const { pathname } = useLocation()

  return (
    <div
      className="fixed top-0 left-0 right-0 z-50 flex items-center justify-center"
      style={{ height: 'clamp(72px, 12vh, 100px)' }}
    >
      <div
        className="absolute inset-0"
        style={{
          background: 'linear-gradient(to bottom, rgba(0,0,0,0.9) 0%, rgba(0,0,0,0.6) 60%, transparent 100%)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
        }}
      />

      <nav className="relative flex items-center gap-[clamp(16px,2vw,40px)] px-[clamp(24px,3vw,48px)]">
        {tabs.map(({ to, icon: Icon, label, end }) => {
          const active = isActiveTab(to, end, pathname)
          return (
            <div
              key={to}
              role="tab"
              tabIndex={0}
              data-nav-item
              data-nav-id={`tab:${to}`}
              data-nav-kind="tab"
              data-nav-axis="horizontal"
              data-nav-group="top-tabs"
              onClick={() => navigate(to)}
              className={`inline-flex items-center justify-center gap-[clamp(6px,0.42vw,10px)] rounded-full font-medium transition-all duration-200 cursor-pointer whitespace-nowrap focus:ring-2 focus:ring-accent focus:ring-offset-2 focus:ring-offset-transparent focus:outline-none ${
                active
                  ? 'bg-white/15 backdrop-blur-md border border-white/20 text-white shadow-[0_2px,12px_rgba(255,255,255,0.08)]'
                  : 'text-white/60 hover:text-white hover:bg-white/8'
              }`}
              style={{
                fontSize: 'clamp(15px, 1vw, 18px)',
                padding: 'clamp(8px, 0.63vw, 14px) clamp(14px, 1.46vw, 24px)',
              }}
            >
              <Icon size={16} />
              <span>{label}</span>
            </div>
          )
        })}
      </nav>
    </div>
  )
}
