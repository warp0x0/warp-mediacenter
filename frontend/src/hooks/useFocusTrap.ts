/**
 * useFocusTrap — traps keyboard focus inside a container element.
 *
 * When `open` is true:
 *   1. Saves the currently focused element (to restore later).
 *   2. Focuses the first focusable element inside the container.
 *   3. Intercepts Tab / Shift+Tab to cycle within the container.
 *   4. Listens for Escape to call onClose.
 *
 * When `open` becomes false, restores focus to the previously focused element.
 *
 * Usage:
 *   const containerRef = useRef<HTMLDivElement>(null)
 *   useFocusTrap(containerRef, open, onClose)
 *   return <div ref={containerRef}>...</div>
 */

import { useEffect, useRef, useCallback } from 'react'

const FOCUSABLE_SEL = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(',')

function getFocusables(container: HTMLElement): HTMLElement[] {
  return Array.from(container.querySelectorAll<HTMLElement>(FOCUSABLE_SEL)).filter((el) => {
    const r = el.getBoundingClientRect()
    return r.width > 0 && r.height > 0
  })
}

export function useFocusTrap(
  containerRef: React.RefObject<HTMLElement | null>,
  open: boolean,
  onClose?: () => void,
) {
  const previousFocusRef = useRef<HTMLElement | null>(null)

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      const container = containerRef.current
      if (!container) return

      // Escape closes the dialog
      if (e.key === 'Escape' && onClose) {
        e.preventDefault()
        onClose()
        return
      }

      // Tab / Shift+Tab trapping
      if (e.key !== 'Tab') return

      const focusables = getFocusables(container)
      if (!focusables.length) return

      const first = focusables[0]
      const last = focusables[focusables.length - 1]

      if (e.shiftKey) {
        // Shift+Tab: if at first element, wrap to last
        if (document.activeElement === first) {
          e.preventDefault()
          last.focus()
        }
      } else {
        // Tab: if at last element, wrap to first
        if (document.activeElement === last) {
          e.preventDefault()
          first.focus()
        }
      }
    },
    [containerRef, onClose],
  )

  useEffect(() => {
    if (!open) return

    // Save current focus
    previousFocusRef.current = document.activeElement as HTMLElement | null

    // Focus the first focusable element inside the container
    const container = containerRef.current
    if (container) {
      // Small delay to allow AnimatePresence to mount the DOM
      const timer = setTimeout(() => {
        const focusables = getFocusables(container)
        if (focusables.length) {
          focusables[0].focus()
        } else {
          // If no focusable elements, focus the container itself
          container.focus()
        }
      }, 50)
      return () => clearTimeout(timer)
    }
  }, [open, containerRef])

  useEffect(() => {
    if (!open) return

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [open, handleKeyDown])

  // Restore focus when dialog closes
  useEffect(() => {
    if (open) return
    const prev = previousFocusRef.current
    if (prev && typeof prev.focus === 'function') {
      // Use setTimeout to ensure the dialog is fully unmounted first
      const timer = setTimeout(() => {
        prev.focus()
      }, 50)
      return () => clearTimeout(timer)
    }
  }, [open])
}
