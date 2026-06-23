import { BookmarkPlus } from 'lucide-react'
import CollectionSubTab from './CollectionSubTab'

interface Props {
  mediaType: 'movie' | 'show'
  setMediaType: (t: 'movie' | 'show') => void
  sortValue: string
  setSortValue: (s: string) => void
}

export default function WishlistSubTab({ mediaType, setMediaType, sortValue, setSortValue }: Props) {
  return (
    <CollectionSubTab
      collectionType="wishlist"
      EmptyIcon={BookmarkPlus}
      emptyTitle="Your wishlist is empty."
      emptyHint="Tap the + icon on any movie or show detail page to add it."
      mediaType={mediaType}
      setMediaType={setMediaType}
      sortValue={sortValue}
      setSortValue={setSortValue}
    />
  )
}
