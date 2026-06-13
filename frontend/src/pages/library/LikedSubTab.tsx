import { Heart } from 'lucide-react'
import CollectionSubTab from './CollectionSubTab'

export default function LikedSubTab() {
  return (
    <CollectionSubTab
      collectionType="liked"
      EmptyIcon={Heart}
      emptyTitle="Your liked titles will appear here."
      emptyHint="Tap the heart icon on any movie or show detail page to like it."
    />
  )
}
