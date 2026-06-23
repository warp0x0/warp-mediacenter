import { useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X } from 'lucide-react'
import { useFocusTrap } from '@/hooks/useFocusTrap'

interface HelpDialogProps {
  open: boolean
  onClose: () => void
}

const shortcuts = [
  { key: '/', description: 'Toggle search' },
  { key: '?', description: 'Show this help dialog' },
  { key: 'f', description: 'Toggle fullscreen' },
  { key: 'Escape', description: 'Go back / close' },
  { key: '← →', description: 'Navigate between cards' },
  { key: '↑ ↓', description: 'Navigate between rows' },
  { key: 'Enter', description: 'Open selected item' },
]

export default function HelpDialog({ open, onClose }: HelpDialogProps) {
  const dialogRef = useRef<HTMLDivElement>(null)
  useFocusTrap(dialogRef, open, onClose)

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 z-40"
            onClick={onClose}
          />
          <motion.div
            ref={dialogRef}
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50 bg-bg-panel backdrop-blur-xl border border-white/10 rounded-card w-[clamp(300px,28vw,500px)] p-[clamp(16px,1.67vw,32px)]"
          >
            <div className="flex items-center justify-between mb-[clamp(12px,1.25vw,24px)]">
              <h2 className="text-[var(--section-title-size)] font-bold">Keyboard Shortcuts</h2>
              <button onClick={onClose} className="text-fg-muted hover:text-fg-primary cursor-pointer">
                <X size={20} />
              </button>
            </div>
            <div className="space-y-[clamp(4px,0.31vw,8px)]">
              {shortcuts.map((s) => (
                <div key={s.key} className="flex items-center justify-between py-[clamp(4px,0.31vw,8px)]">
                  <span className="text-fg-muted text-subtitle">{s.description}</span>
                  <kbd className="px-[clamp(6px,0.52vw,12px)] py-[clamp(2px,0.16vw,4px)] bg-white/10 border border-white/10 rounded-pill text-subtitle font-mono text-fg-white">
                    {s.key}
                  </kbd>
                </div>
              ))}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
