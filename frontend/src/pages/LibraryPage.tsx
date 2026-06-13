import { useSearchParams } from 'react-router-dom'
import { Heart, Plus, Compass, HardDrive } from 'lucide-react'
import LikedSubTab from '@/pages/library/LikedSubTab'
import WishlistSubTab from '@/pages/library/WishlistSubTab'
import DiscoverSubTab from '@/pages/library/DiscoverSubTab'
import LocalSubTab from '@/pages/library/LocalSubTab'

type Tab = 'liked' | 'wishlist' | 'discover' | 'local'

const SUB_TABS: { id: Tab; label: string; Icon: React.ElementType }[] = [
  { id: 'liked',    label: 'Liked',     Icon: Heart     },
  { id: 'wishlist', label: 'Wishlist',  Icon: Plus      },
  { id: 'discover', label: 'Discover',  Icon: Compass   },
  { id: 'local',    label: 'Local',     Icon: HardDrive },
]

export default function LibraryPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const activeTab = (searchParams.get('tab') ?? 'liked') as Tab

  const setTab = (tab: Tab) => setSearchParams({ tab }, { replace: true })

  return (
    <div
      className="flex flex-col h-full bg-bg-primary overflow-hidden"
      style={{ paddingTop: 'var(--tabbar-height)' }}
    >
      {/* Page header */}
      <div
        className="flex-shrink-0 text-center"
        style={{ padding: 'clamp(16px,2vh,28px) clamp(24px,2vw,48px) 0' }}
      >
        <h1
          className="font-extrabold text-fg-white tracking-tight"
          style={{ fontSize: 'var(--page-title-size)' }}
        >
          All Your Collections In One Place
        </h1>
      </div>

      {/* Sub-tab bar */}
      <div
        className="flex-shrink-0 flex justify-center"
        style={{ padding: 'clamp(12px,1.5vh,20px) 0 clamp(10px,1.2vh,18px)', marginBottom: '10px', marginTop: '15px'}}
      >
        <nav className="flex items-center gap-[clamp(10px,1.2vw,24px)]">
          {SUB_TABS.map(({ id, label, Icon }) => {
            const isActive = activeTab === id
            return (
              <button
                key={id}
                onClick={() => setTab(id)}
                className={`inline-flex items-center justify-center gap-[clamp(5px,0.35vw,8px)] rounded-full font-medium transition-all duration-200 cursor-pointer whitespace-nowrap ${
                  isActive
                    ? 'bg-white/15 backdrop-blur-md border border-white/20 text-white shadow-[0_2px_12px_rgba(255,255,255,0.08)]'
                    : 'text-white/60 hover:text-white hover:bg-white/8'
                }`}
                style={{
                  fontSize: 'clamp(14px, 0.9vw, 17px)',
                  padding: 'clamp(7px, 0.55vw, 12px) clamp(13px, 1.3vw, 22px)',
                }}
              >
                <Icon size={15} />
                <span>{label}</span>
              </button>
            )
          })}
        </nav>
      </div>

      {/* Divider */}
      <div className="flex-shrink-0 h-px bg-white/8 mx-[clamp(24px,2vw,48px)]" />

      {/* Active sub-tab content */}
      <div className="flex-1 min-h-0 overflow-hidden">
        {activeTab === 'liked'    && <LikedSubTab />}
        {activeTab === 'wishlist' && <WishlistSubTab />}
        {activeTab === 'discover' && <DiscoverSubTab />}
        {activeTab === 'local'    && <LocalSubTab />}
      </div>
    </div>
  )
}
