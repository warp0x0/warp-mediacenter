import { useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'

interface KeyboardNavOptions {
  onToggleSearch: () => void
  onToggleHelp: () => void
  onFocusNext?: () => void
  onFocusPrev?: () => void
  onFocusNextRow?: () => void
  onFocusPrevRow?: () => void
  onOpenDetail?: () => void
}

export function useKeyboardNav({
  onToggleSearch,
  onToggleHelp,
  onFocusNext,
  onFocusPrev,
  onFocusNextRow,
  onFocusPrevRow,
  onOpenDetail,
}: KeyboardNavOptions) {
  const navigate = useNavigate()

  const goBack = useCallback(() => {
    navigate(-1)
  }, [navigate])

  const toggleFullscreen = useCallback(() => {
    if (document.fullscreenElement) {
      document.exitFullscreen()
    } else {
      document.documentElement.requestFullscreen()
    }
  }, [])

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable) {
        return
      }

      switch (e.key) {
        case '/':
          e.preventDefault()
          onToggleSearch()
          break
        case '?':
          e.preventDefault()
          onToggleHelp()
          break
        case 'f':
          e.preventDefault()
          toggleFullscreen()
          break
        case 'Escape':
          goBack()
          break
        case 'ArrowRight':
          onFocusNext?.()
          break
        case 'ArrowLeft':
          onFocusPrev?.()
          break
        case 'ArrowDown':
          onFocusNextRow?.()
          break
        case 'ArrowUp':
          onFocusPrevRow?.()
          break
        case 'Enter':
          onOpenDetail?.()
          break
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [onToggleSearch, onToggleHelp, toggleFullscreen, goBack, onFocusNext, onFocusPrev, onFocusNextRow, onFocusPrevRow, onOpenDetail])
}
