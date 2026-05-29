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

export default function TabBar() {
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
        {tabs.map(({ to, icon: Icon, label, end }) => (
          <NavLink key={to} to={to} end={end} className="no-underline">
            {({ isActive }) => (
              <span
                className={`inline-flex items-center justify-center gap-[clamp(6px,0.42vw,10px)] rounded-full font-medium transition-all duration-200 cursor-pointer whitespace-nowrap ${
                  isActive
                    ? 'bg-white/15 backdrop-blur-md border border-white/20 text-white shadow-[0_2px_12px_rgba(255,255,255,0.08)]'
                    : 'text-white/60 hover:text-white hover:bg-white/8'
                }`}
                style={{
                  fontSize: 'clamp(15px, 1vw, 18px)',
                  padding: isActive
                    ? 'clamp(8px, 0.63vw, 14px) clamp(14px, 1.46vw, 24px)'
                    : 'clamp(8px, 0.63vw, 14px) clamp(14px, 1.46vw, 24px)',
                }}
              >
                <Icon size={16} />
                <span>{label}</span>
              </span>
            )}
          </NavLink>
        ))}
      </nav>
    </div>
  )
}
