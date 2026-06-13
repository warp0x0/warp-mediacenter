import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { BackdropProvider } from '@/contexts/BackdropContext'
import { ToastProvider } from '@/components/shared/ErrorToast'
import { bootstrapTauriBridge } from '@/lib/tauri'
import App from './App'
import './index.css'

void bootstrapTauriBridge().then((result) => {
  if (!result.active) return
  if (result.error) {
    console.warn('[tauri] bridge bootstrap failed:', result.error)
    return
  }
  console.info('[tauri] bridge ready:', result.appInfo)
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <ToastProvider>
        <BackdropProvider>
          <App />
        </BackdropProvider>
      </ToastProvider>
    </BrowserRouter>
  </StrictMode>,
)
