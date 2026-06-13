import { BookmarkPlus } from 'lucide-react'
import CollectionSubTab from './CollectionSubTab'

export default function WishlistSubTab() {
  return (
    <CollectionSubTab
      collectionType="wishlist"
      EmptyIcon={BookmarkPlus}
      emptyTitle="Your wishlist is empty."
      emptyHint="Tap the + icon on any movie or show detail page to add it."
    />
  )
}
