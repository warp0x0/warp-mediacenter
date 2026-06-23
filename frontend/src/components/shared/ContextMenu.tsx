import { useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Loader2 } from 'lucide-react'

export interface ContextMenuItem {
  key: string
  label: string
  icon?: React.ReactNode
  disabled?: boolean
  destructive?: boolean
}

interface ContextMenuProps {
  open: boolean
  items: ContextMenuItem[]
  onSelect: (key: string) => void
  onClose: () => void
  anchorRef?: React.RefObject<HTMLElement | null>
  loading?: boolean
}

function getMenuButtons(el: HTMLElement): HTMLButtonElement[] {
  return Array.from(el.querySelectorAll<HTMLButtonElement>('button:not([disabled])'))
}

export default function ContextMenu({ open, items, onSelect, onClose, anchorRef, loading }: ContextMenuProps) {
  const menuRef = useRef<HTMLDivElement>(null)
  const onCloseRef = useRef(onClose)
  useEffect(() => { onCloseRef.current = onClose })

  const [position, setPosition] = useState<{ top: number; left: number }>({ top: 0, left: 0 })

  useEffect(() => {
    if (!open) return
    const menuWidth = 220
    const menuHeight = items.length * 44 + 16

    if (anchorRef?.current) {
      const rect = anchorRef.current.getBoundingClientRect()
      // Read the computed --card-radius from the anchor to align the menu
      // with the visual (rounded) edge of the card rather than the raw
      // bounding-box edge.  CSS transforms scale the radius too, so we
      // compute the effective radius from the element's transform matrix.
      const anchor = anchorRef.current
      const rawRadius = parseFloat(
        getComputedStyle(anchor).getPropertyValue('--card-radius')
      ) || 0
      // Extract scale factor from the element's transform matrix (identity if none)
      const cs = getComputedStyle(anchor)
      const matrix = cs.transform && cs.transform !== 'none'
        ? new DOMMatrixReadOnly(cs.transform)
        : new DOMMatrixReadOnly()
      const scaleX = matrix.a  // horizontal scale component
      const effectiveRadius = rawRadius * (scaleX || 1)

      let top = rect.bottom
      let left = rect.left + effectiveRadius

      if (top + menuHeight > window.innerHeight) {
        top = rect.top - menuHeight
      }
      if (left < 8) left = 8
      if (left + menuWidth > window.innerWidth - 8) {
        left = window.innerWidth - menuWidth - 8
      }
      setPosition({ top, left })
    } else {
      setPosition({
        top: (window.innerHeight - menuHeight) / 2,
        left: (window.innerWidth - menuWidth) / 2,
      })
    }
  }, [open, anchorRef, items.length])

  // Close on click outside
  useEffect(() => {
    if (!open) return
    const handler = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        onCloseRef.current()
      }
    }
    const timer = setTimeout(() => {
      document.addEventListener('mousedown', handler)
    }, 200)
    return () => {
      clearTimeout(timer)
      document.removeEventListener('mousedown', handler)
    }
  }, [open])

  // Window-level capture listener for arrow keys and Escape.  Handle all menu
  // arrow navigation here so it remains reliable across route remounts and
  // never leaks to NavigationProvider's global keydown handler.
  useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => {
      if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp' && e.key !== 'ArrowLeft' && e.key !== 'ArrowRight' && e.key !== 'Escape') return

      const el = menuRef.current
      if (!el) {
        // Menu DOM not committed yet (AnimatePresence timing) — still block
        // the event so NavigationProvider doesn't steal focus.
        e.stopImmediatePropagation()
        return
      }

      // Escape → close the menu
      if (e.key === 'Escape') {
        e.stopImmediatePropagation()
        onCloseRef.current()
        return
      }

      e.stopImmediatePropagation()

      // Left/Right have no meaning in a vertical context menu, but they must
      // still be swallowed so focus doesn't escape to the page behind it.
      if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
        e.preventDefault()
        return
      }

      const active = document.activeElement as HTMLElement | null
      const buttons = getMenuButtons(el)
      if (!buttons.length) return

      e.preventDefault()
      const idx = active && el.contains(active)
        ? buttons.indexOf(active as HTMLButtonElement)
        : -1
      if (idx === -1) {
        if (e.key === 'ArrowDown') {
          buttons[0].focus()
        } else {
          buttons[buttons.length - 1].focus()
        }
        return
      }

      const next = e.key === 'ArrowDown'
        ? (idx + 1) % buttons.length
        : (idx - 1 + buttons.length) % buttons.length
      buttons[next].focus()
    }
    window.addEventListener('keydown', handler, true)
    return () => window.removeEventListener('keydown', handler, true)
  }, [open])

  // Intercept all keyboard and custom events inside the context menu so they
  // don't leak to NavigationProvider's global handler or parent longpress listeners.
  useEffect(() => {
    if (!open) return

    const attach = () => {
      const el = menuRef.current
      if (!el) return null

      const onKeyDown = (e: KeyboardEvent) => {
        if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Enter', ' '].includes(e.key)) {
          e.stopPropagation()

          if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
            e.preventDefault()
            const buttons = getMenuButtons(el)
            const current = document.activeElement as HTMLElement
            const idx = buttons.indexOf(current as HTMLButtonElement)
            if (idx === -1) {
              buttons[0]?.focus()
            } else {
              const next = e.key === 'ArrowDown'
                ? (idx + 1) % buttons.length
                : (idx - 1 + buttons.length) % buttons.length
              buttons[next].focus()
            }
          }

          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault()
            const btn = document.activeElement as HTMLButtonElement
            if (btn && el.contains(btn) && !btn.disabled) {
              btn.click()
            }
          }
        }
      }

      const onLongpress = (e: Event) => {
        e.stopPropagation()
      }

      el.addEventListener('keydown', onKeyDown)
      el.addEventListener('remotelongpress', onLongpress)
      return { el, onKeyDown, onLongpress }
    }

    // Try attaching immediately; if menuRef.current is null (AnimatePresence
    // hasn't committed yet), retry after a short delay.
    let cleanup: ReturnType<typeof attach> = attach()
    if (!cleanup) {
      const timer = setTimeout(() => { cleanup = attach() ?? null }, 16)
      return () => { clearTimeout(timer); cleanup?.el.removeEventListener('keydown', cleanup.onKeyDown); cleanup?.el.removeEventListener('remotelongpress', cleanup.onLongpress) }
    }
    return () => {
      cleanup?.el.removeEventListener('keydown', cleanup.onKeyDown)
      cleanup?.el.removeEventListener('remotelongpress', cleanup.onLongpress)
    }
  }, [open])

  return (
    <>
      <AnimatePresence>
        {open && (
          <motion.div
            key="ctx-backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[80]"
            onClick={onClose}
          />
        )}
      </AnimatePresence>
      <AnimatePresence>
        {open && (
          <motion.div
            key="ctx-menu"
            ref={menuRef}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ duration: 0.12, ease: [0.22, 1, 0.36, 1] }}
            className="fixed z-[81] bg-bg-panel/95 backdrop-blur-xl border border-white/10 rounded-card shadow-2xl overflow-hidden"
            role="menu"
            style={{
              top: position.top,
              left: position.left,
              width: 220,
              padding: '6px',
            }}
          >
            {loading && (
              <div className="flex items-center justify-center gap-2 py-3 text-fg-muted text-subtitle">
                <Loader2 size={14} className="animate-spin" />
                <span>Updating...</span>
              </div>
            )}
            {!loading && items.map((item) => (
              <button
                key={item.key}
                onClick={() => !item.disabled && onSelect(item.key)}
                disabled={item.disabled}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-btn text-left transition-colors cursor-pointer
                  ${item.disabled
                    ? 'opacity-40 cursor-not-allowed'
                    : item.destructive
                      ? 'hover:bg-red-500/15 text-red-400'
                      : 'hover:bg-white/8 text-fg-white'
                  }`}
                style={{ fontSize: 'var(--body-size)' }}
              >
                {item.icon && <span className="shrink-0">{item.icon}</span>}
                <span className="font-medium">{item.label}</span>
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
}
