import { useEffect, useCallback } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { X } from 'lucide-react'

interface TrailerDialogProps {
  url: string | null
  onClose: () => void
}

/** Extract a YouTube video ID from any YouTube URL format. */
function extractYouTubeId(url: string): string | null {
  try {
    const parsed = new URL(url)

    // https://youtu.be/<id>
    if (parsed.hostname === 'youtu.be') {
      const id = parsed.pathname.slice(1).split('?')[0]
      return id || null
    }

    // https://www.youtube.com/watch?v=<id>
    const v = parsed.searchParams.get('v')
    if (v) return v

    // https://www.youtube.com/embed/<id>
    const embedMatch = parsed.pathname.match(/^\/embed\/([^/?]+)/)
    if (embedMatch) return embedMatch[1]

    // https://www.youtube.com/shorts/<id>
    const shortsMatch = parsed.pathname.match(/^\/shorts\/([^/?]+)/)
    if (shortsMatch) return shortsMatch[1]
  } catch {
    // not a valid URL — try a raw ID (11 alphanumeric chars)
    if (/^[a-zA-Z0-9_-]{11}$/.test(url)) return url
  }
  return null
}

export default function TrailerDialog({ url, onClose }: TrailerDialogProps) {
  const videoId = url ? extractYouTubeId(url) : null
  const embedUrl = videoId
    ? `https://www.youtube.com/embed/${videoId}?autoplay=1&rel=0&modestbranding=1`
    : null

  // Close on Escape key
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    },
    [onClose],
  )

  useEffect(() => {
    if (!url) return
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [url, handleKeyDown])

  return (
    <AnimatePresence>
      {url && (
        <motion.div
          key="trailer-overlay"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.22 }}
          className="fixed inset-0 z-[9999] flex items-center justify-center"
          style={{ background: 'rgba(0, 0, 0, 0.88)', backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)' }}
          onClick={onClose}
        >
          {/* Accent top stripe */}
          <div
            className="absolute top-0 left-0 right-0 pointer-events-none"
            style={{ height: 3, background: 'linear-gradient(90deg, var(--accent) 0%, transparent 100%)', opacity: 0.7 }}
          />

          {/* Dialog panel — stops click propagation so clicking the video doesn't close */}
          <motion.div
            initial={{ scale: 0.92, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.92, opacity: 0 }}
            transition={{ duration: 0.22, ease: [0.25, 0.1, 0.25, 1] }}
            className="relative"
            style={{ width: 'clamp(320px, 66vw, 960px)' }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* 16:9 iframe container */}
            <div
              className="relative w-full overflow-hidden"
              style={{
                paddingTop: '56.25%',
                borderRadius: 12,
                boxShadow: '0 24px 80px rgba(0,0,0,0.8), 0 0 0 1px rgba(255,255,255,0.06)',
                background: '#000',
              }}
            >
              {embedUrl ? (
                <iframe
                  src={embedUrl}
                  title="Trailer"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                  allowFullScreen
                  className="absolute inset-0 w-full h-full"
                  style={{ border: 'none' }}
                />
              ) : (
                <div className="absolute inset-0 flex items-center justify-center text-white/50 text-sm">
                  Unable to load trailer
                </div>
              )}

              {/* Close button — overlaid inside the top-right corner of the video */}
              <button
                onClick={onClose}
                className="absolute top-3 right-3 z-10 flex items-center gap-1.5 text-white/80 hover:text-white transition-colors cursor-pointer"
                style={{
                  background: 'rgba(0,0,0,0.55)',
                  backdropFilter: 'blur(6px)',
                  WebkitBackdropFilter: 'blur(6px)',
                  border: '1px solid rgba(255,255,255,0.12)',
                  borderRadius: 8,
                  padding: '5px 10px',
                  fontSize: 12,
                }}
              >
                <span className="uppercase tracking-widest font-semibold">Close</span>
                <X size={14} />
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
