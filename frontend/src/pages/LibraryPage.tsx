import { useSearchParams } from 'react-router-dom'
import { Heart, Plus, Compass, HardDrive } from 'lucide-react'
import LikedSubTab from '@/pages/library/LikedSubTab'
import WishlistSubTab from '@/pages/library/WishlistSubTab'
import DiscoverSubTab from '@/pages/library/DiscoverSubTab'
import LocalSubTab from '@/pages/library/LocalSubTab'

type Tab = 'liked' | 'wishlist' | 'discover' | 'local'
type MediaType = 'movie' | 'show'

const SUB_TABS: { id: Tab; label: string; Icon: React.ElementType }[] = [
  { id: 'liked',    label: 'Liked',     Icon: Heart     },
  { id: 'wishlist', label: 'Wishlist',  Icon: Plus      },
  { id: 'discover', label: 'Discover',  Icon: Compass   },
  { id: 'local',    label: 'Local',     Icon: HardDrive },
]

export default function LibraryPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const activeTab = (searchParams.get('tab') ?? 'liked') as Tab
  const mediaType = (searchParams.get('type') ?? 'movie') as MediaType
  const sortValue = (searchParams.get('sort') ?? 'added_at-desc') as string

  const setTab = (tab: Tab) =>
    setSearchParams({ tab, type: mediaType, sort: sortValue }, { replace: true })
  const setMediaType = (type: MediaType) =>
    setSearchParams({ tab: activeTab, type, sort: sortValue }, { replace: true })
  const setSortValue = (sort: string) =>
    setSearchParams({ tab: activeTab, type: mediaType, sort }, { replace: true })

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
                data-nav-item
                data-nav-id={`library-tab:${id}`}
                data-nav-kind="tab"
                data-nav-axis="horizontal"
                data-nav-group="library-tabs"
                onClick={() => setTab(id)}
                {...(id === 'liked' ? { 'data-nav-initial': '' } : {})}
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
        {activeTab === 'liked'    && <LikedSubTab    mediaType={mediaType} setMediaType={setMediaType} sortValue={sortValue} setSortValue={setSortValue} />}
        {activeTab === 'wishlist' && <WishlistSubTab mediaType={mediaType} setMediaType={setMediaType} sortValue={sortValue} setSortValue={setSortValue} />}
        {activeTab === 'discover' && <DiscoverSubTab mediaType={mediaType} setMediaType={setMediaType} />}
        {activeTab === 'local'    && <LocalSubTab    mediaType={mediaType} setMediaType={setMediaType} />}
      </div>
    </div>
  )
}
