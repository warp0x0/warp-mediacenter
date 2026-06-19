import { Heart } from 'lucide-react'
import CollectionSubTab from './CollectionSubTab'

interface Props {
  mediaType: 'movie' | 'show'
  setMediaType: (t: 'movie' | 'show') => void
}

export default function LikedSubTab({ mediaType, setMediaType }: Props) {
  return (
    <CollectionSubTab
      collectionType="liked"
      EmptyIcon={Heart}
      emptyTitle="Your liked titles will appear here."
      emptyHint="Tap the heart icon on any movie or show detail page to like it."
      mediaType={mediaType}
      setMediaType={setMediaType}
    />
  )
}
