import { useEffect, useState, useCallback, createContext, useContext, type ReactNode } from 'react'
import { X } from 'lucide-react'
import { AnimatePresence, motion } from 'framer-motion'

export interface Toast {
  id: string
  message: string
  type: 'error' | 'warning' | 'info'
}

interface ToastContextValue {
  toasts: Toast[]
  addToast: (message: string, type?: Toast['type']) => void
  removeToast: (id: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const addToast = useCallback((message: string, type: Toast['type'] = 'error') => {
    const id = crypto.randomUUID()
    setToasts((prev) => [...prev, { id, message, type }])
  }, [])

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  return (
    <ToastContext.Provider value={{ toasts, addToast, removeToast }}>
      {children}
      <ErrorToast />
    </ToastContext.Provider>
  )
}

export function useToast() {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error('useToast must be used within ToastProvider')
  return ctx
}

function ErrorToast() {
  const { toasts, removeToast } = useContext(ToastContext)!

  useEffect(() => {
    const timers = toasts.map((t) =>
      setTimeout(() => removeToast(t.id), 5000),
    )
    return () => timers.forEach(clearTimeout)
  }, [toasts, removeToast])

  const colorMap: Record<Toast['type'], string> = {
    error: 'bg-danger',
    warning: 'bg-warning',
    info: 'bg-accent',
  }

  return (
    <div className="fixed bottom-[clamp(16px,2vh,32px)] right-[clamp(16px,1.67vw,32px)] z-50 flex flex-col gap-[clamp(6px,0.42vw,10px)] pointer-events-none">
      <AnimatePresence>
        {toasts.map((toast) => (
          <motion.div
            key={toast.id}
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.95 }}
            className={`${colorMap[toast.type]} text-white px-[clamp(12px,1.04vw,20px)] py-[clamp(8px,0.63vw,14px)] rounded-btn text-body font-medium shadow-lg pointer-events-auto flex items-center gap-[clamp(8px,0.63vw,14px)] max-w-[clamp(280px,20vw,400px)]`}
          >
            <span className="flex-1">{toast.message}</span>
            <button
              onClick={() => removeToast(toast.id)}
              className="opacity-70 hover:opacity-100 cursor-pointer"
            >
              <X size={16} />
            </button>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}
