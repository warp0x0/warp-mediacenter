import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { BackdropProvider } from '@/contexts/BackdropContext'
import { ToastProvider } from '@/components/shared/ErrorToast'
import App from './App'
import './index.css'

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
