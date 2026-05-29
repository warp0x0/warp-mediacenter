import { createContext, useContext, useState, useCallback, type ReactNode } from 'react'

interface BackdropState {
  url: string | null
  isVisible: boolean
}

interface BackdropContextValue {
  backdrop: BackdropState
  setBackdrop: (url: string | null) => void
  clearBackdrop: () => void
}

const BackdropContext = createContext<BackdropContextValue | null>(null)

export function BackdropProvider({ children }: { children: ReactNode }) {
  const [backdrop, setBackdropState] = useState<BackdropState>({
    url: null,
    isVisible: false,
  })

  const setBackdrop = useCallback((url: string | null) => {
    setBackdropState({ url, isVisible: true })
  }, [])

  const clearBackdrop = useCallback(() => {
    setBackdropState({ url: null, isVisible: false })
  }, [])

  return (
    <BackdropContext.Provider value={{ backdrop, setBackdrop, clearBackdrop }}>
      {children}
    </BackdropContext.Provider>
  )
}

export function useBackdrop() {
  const ctx = useContext(BackdropContext)
  if (!ctx) throw new Error('useBackdrop must be used within BackdropProvider')
  return ctx
}
