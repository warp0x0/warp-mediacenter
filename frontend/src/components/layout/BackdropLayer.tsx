import { motion, AnimatePresence } from 'framer-motion'
import { useBackdrop } from '@/contexts/BackdropContext'

const IMAGE_BASE = 'https://image.tmdb.org/t/p'

export default function BackdropLayer() {
  const { backdrop } = useBackdrop()

  const backdropUrl = backdrop.url
    ? `${IMAGE_BASE}/w1280${backdrop.url}`
    : null

  return (
    <div className="fixed inset-0 z-[-1] pointer-events-none">
      <AnimatePresence>
        {backdropUrl && (
          <motion.div
            key={backdropUrl}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.4 }}
            className="absolute inset-0"
          >
            <div
              className="absolute inset-0 bg-cover bg-center bg-no-repeat"
                style={{ backgroundImage: `url(${backdropUrl})` }}
            />
            <div className="absolute inset-0 bg-black/40" />
            <div
              className="absolute inset-0"
              style={{
                background:
                  'linear-gradient(to top, var(--bg-primary) 0%, transparent 30%, transparent 80%, var(--bg-primary) 100%)',
              }}
            />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
