import { useState, useEffect, useCallback } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { X, ExternalLink, CheckCircle2, AlertCircle, Loader2, KeyRound, Copy, Check } from 'lucide-react'
import { useAuthTrakt, useAuthDebrid, startTraktAuth, startDebridAuth, refreshDebridToken } from '@/hooks/useAuth'
import type { AuthStatus } from '@/lib/types'

type AuthType = 'trakt' | 'debrid'

interface AuthDialogProps {
  open: boolean
  type: AuthType
  onClose: () => void
}

type Step = 'idle' | 'refreshing' | 'started' | 'success' | 'error'

export default function AuthDialog({ open, type, onClose }: AuthDialogProps) {
  const [step, setStep]                   = useState<Step>('idle')
  const [userCode, setUserCode]           = useState<string | null>(null)
  const [verificationUrl, setVerificationUrl] = useState<string | null>(null)
  const [errorMsg, setErrorMsg]           = useState<string | null>(null)
  const [polling, setPolling]             = useState(false)
  const [copied, setCopied]               = useState(false)

  const traktStatus  = useAuthTrakt(polling && type === 'trakt' ? {} : undefined)
  const debridStatus = useAuthDebrid(polling && type === 'debrid' ? {} : undefined)

  const authStatus: AuthStatus | undefined =
    type === 'trakt' ? traktStatus.data : debridStatus.data

  const label      = type === 'trakt' ? 'Trakt' : 'Real Debrid'
  const accentColor = type === 'debrid' ? 'var(--accent)' : '#e8462a'

  const handleClose = useCallback(() => {
    setStep('idle')
    setUserCode(null)
    setVerificationUrl(null)
    setErrorMsg(null)
    setPolling(false)
    setCopied(false)
    onClose()
  }, [onClose])

  useEffect(() => {
    if (!open) {
      setStep('idle')
      setPolling(false)
      setCopied(false)
    }
  }, [open])

  useEffect(() => {
    if (!polling || !authStatus) return
    if (authStatus.authenticated) {
      setStep('success')
      setPolling(false)
      debridStatus.mutate?.()
      traktStatus.mutate?.()
      setTimeout(handleClose, 2200)
    } else if (authStatus.expired || authStatus.denied) {
      setStep('error')
      setPolling(false)
      setErrorMsg(authStatus.error || 'Authorization expired or denied. Please try again.')
    }
  }, [authStatus, polling, handleClose])

  async function handleStart() {
    setErrorMsg(null)

    if (type === 'debrid') {
      setStep('refreshing')
      try {
        const result = await refreshDebridToken()
        if (result.refreshed || result.authenticated) {
          setStep('success')
          setTimeout(handleClose, 2200)
          return
        }
      } catch {
        // fall through to device flow
      }
    }

    setStep('started')
    try {
      if (type === 'trakt') {
        const result = await startTraktAuth()
        setUserCode(result.user_code)
        setVerificationUrl(result.verification_url)
      } else {
        const result = await startDebridAuth()
        setUserCode(result.user_code)
        setVerificationUrl(result.verification_url)
      }
      setPolling(true)
    } catch {
      setStep('error')
      setErrorMsg('Failed to start authorization. Check your connection and try again.')
    }
  }

  function handleRetry() {
    setStep('idle')
    setPolling(false)
    setUserCode(null)
    setVerificationUrl(null)
    setErrorMsg(null)
    setCopied(false)
  }

  async function handleCopy() {
    if (!userCode) return
    try {
      await navigator.clipboard.writeText(userCode)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      /* clipboard not available */
    }
  }

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50"
            style={{ background: 'rgba(0,0,0,0.78)', backdropFilter: 'blur(6px)', WebkitBackdropFilter: 'blur(6px)' }}
            onClick={handleClose}
          />

          {/* Dialog */}
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.97 }}
            transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
            className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-50 flex flex-col overflow-hidden rounded-card border border-white/[0.09]"
            style={{
              width: 'clamp(400px, 36vw, 560px)',
              background: 'rgba(10,10,14,0.97)',
              backdropFilter: 'blur(32px)',
              WebkitBackdropFilter: 'blur(32px)',
            }}
          >
            {/* Accent top stripe */}
            <div
              className="h-[3px] w-full shrink-0"
              style={{ background: `linear-gradient(90deg, ${accentColor} 0%, rgba(13,178,226,0.10) 100%)` }}
            />

            {/* ── HEADER ── */}
            <div
              className="flex items-center justify-between shrink-0 border-b border-white/[0.07]"
              style={{ padding: 'clamp(14px,1.6vh,22px) clamp(18px,1.5vw,28px)' }}
            >
              <div className="flex items-center gap-3">
                <div
                  className="flex items-center justify-center rounded-lg shrink-0"
                  style={{
                    width: 'clamp(34px,2.2vw,42px)',
                    height: 'clamp(34px,2.2vw,42px)',
                    background: `rgba(13,178,226,0.18)`,
                    color: accentColor,
                  }}
                >
                  <KeyRound size={16} />
                </div>
                <div>
                  <h2 className="text-white font-bold" style={{ fontSize: 'clamp(14px,1vw,18px)' }}>
                    {label} Authorization
                  </h2>
                  <p className="text-white/35" style={{ fontSize: 'clamp(11px,0.65vw,13px)', marginTop: '1px' }}>
                    {step === 'started' ? 'Complete the steps below to connect' : `Connect your ${label} account`}
                  </p>
                </div>
              </div>

              <button
                onClick={handleClose}
                className="flex items-center justify-center rounded-lg text-white/35 hover:text-white/75 hover:bg-white/[0.07] transition-all duration-150 cursor-pointer shrink-0"
                style={{ width: 'clamp(30px,2vw,36px)', height: 'clamp(30px,2vw,36px)' }}
              >
                <X size={15} />
              </button>
            </div>

            {/* ── BODY ── */}
            <div style={{ padding: 'clamp(18px,2vh,28px) clamp(18px,1.5vw,28px)' }}>

              {/* ── IDLE ── */}
              {step === 'idle' && (
                <div className="flex flex-col gap-5">
                  <p className="text-white/45 leading-relaxed" style={{ fontSize: 'clamp(13px,0.82vw,15px)' }}>
                    {type === 'debrid'
                      ? 'Connect Real Debrid to enable instant torrent streaming. You\'ll be asked to visit a short URL and enter a code on the Real Debrid website.'
                      : 'Connect your Trakt account to enable watch history sync and scrobbling. You\'ll be redirected to the Trakt website to authorize.'}
                  </p>
                  <button
                    onClick={handleStart}
                    className="w-full flex items-center justify-center gap-2 rounded-card font-semibold text-white transition-all duration-150 cursor-pointer"
                    style={{
                      padding: 'clamp(12px,1.2vh,16px)',
                      background: `linear-gradient(135deg, ${accentColor} 0%, rgba(13,178,226,0.7) 100%)`,
                      fontSize: 'clamp(13px,0.85vw,15px)',
                      boxShadow: `0 4px 24px rgba(13,178,226,0.25)`,
                    }}
                  >
                    <KeyRound size={15} />
                    Start Authorization
                  </button>
                </div>
              )}

              {/* ── REFRESHING ── */}
              {step === 'refreshing' && (
                <div className="flex flex-col items-center gap-4 py-6">
                  <Loader2 size={32} className="animate-spin" style={{ color: accentColor }} />
                  <p className="text-white/40" style={{ fontSize: 'clamp(13px,0.82vw,15px)' }}>
                    Checking existing credentials…
                  </p>
                </div>
              )}

              {/* ── STARTED: show URL + code ── */}
              {step === 'started' && (
                <div className="flex flex-col gap-4">

                  {/* Step 1 — open the URL */}
                  <div
                    className="flex flex-col gap-2 rounded-card border border-white/[0.07]"
                    style={{ padding: 'clamp(12px,1.2vh,18px)', background: 'rgba(255,255,255,0.025)' }}
                  >
                    <p
                      className="text-white/40 font-semibold uppercase tracking-wider"
                      style={{ fontSize: 'clamp(10px,0.6vw,11px)' }}
                    >
                      Step 1 — Open the authorization page
                    </p>
                    {verificationUrl && (
                      <button
                        onClick={() => window.open(verificationUrl, '_blank')}
                        className="flex items-center gap-2 w-full rounded-lg border border-white/[0.09] text-left transition-all duration-150 cursor-pointer group"
                        style={{
                          padding: 'clamp(10px,1vh,14px) clamp(12px,1vw,16px)',
                          background: 'rgba(255,255,255,0.03)',
                          fontSize: 'clamp(12px,0.75vw,14px)',
                        }}
                        onMouseEnter={(e) => {
                          ;(e.currentTarget as HTMLButtonElement).style.background = 'rgba(13,178,226,0.08)'
                          ;(e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(13,178,226,0.3)'
                        }}
                        onMouseLeave={(e) => {
                          ;(e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.03)'
                          ;(e.currentTarget as HTMLButtonElement).style.borderColor = 'rgba(255,255,255,0.09)'
                        }}
                      >
                        <ExternalLink size={13} style={{ color: accentColor, flexShrink: 0 }} />
                        <span className="text-white/60 font-mono truncate">{verificationUrl}</span>
                        <span
                          className="ml-auto shrink-0 font-medium"
                          style={{ color: accentColor, fontSize: 'clamp(11px,0.65vw,12px)' }}
                        >
                          Open →
                        </span>
                      </button>
                    )}
                  </div>

                  {/* Step 2 — enter the code */}
                  <div
                    className="flex flex-col gap-3 rounded-card border border-white/[0.07]"
                    style={{ padding: 'clamp(12px,1.2vh,18px)', background: 'rgba(255,255,255,0.025)' }}
                  >
                    <p
                      className="text-white/40 font-semibold uppercase tracking-wider"
                      style={{ fontSize: 'clamp(10px,0.6vw,11px)' }}
                    >
                      Step 2 — Enter this code on the page
                    </p>

                    {userCode && (
                      <div className="flex items-center gap-3">
                        {/* Code display */}
                        <div
                          className="flex-1 text-center font-mono font-bold rounded-lg border border-white/[0.12]"
                          style={{
                            padding: 'clamp(10px,1.1vh,16px)',
                            fontSize: 'clamp(26px,2.2vw,38px)',
                            letterSpacing: '0.18em',
                            color: accentColor,
                            background: `rgba(13,178,226,0.06)`,
                          }}
                        >
                          {userCode}
                        </div>

                        {/* Copy button */}
                        <button
                          onClick={handleCopy}
                          className="flex items-center justify-center rounded-lg border border-white/[0.09] transition-all duration-150 cursor-pointer shrink-0"
                          style={{
                            width: 'clamp(38px,2.6vw,48px)',
                            height: 'clamp(38px,2.6vw,48px)',
                            background: copied ? 'rgba(0,230,118,0.12)' : 'rgba(255,255,255,0.04)',
                            borderColor: copied ? 'rgba(0,230,118,0.35)' : undefined,
                          }}
                          title="Copy code"
                        >
                          {copied
                            ? <Check size={15} className="text-success" />
                            : <Copy size={15} className="text-white/40" />
                          }
                        </button>
                      </div>
                    )}
                  </div>

                  {/* Waiting indicator */}
                  <div
                    className="flex items-center justify-center gap-2 rounded-lg border border-white/[0.06]"
                    style={{
                      padding: 'clamp(10px,1vh,14px)',
                      background: 'rgba(255,255,255,0.02)',
                      fontSize: 'clamp(12px,0.72vw,13px)',
                      color: 'rgba(255,255,255,0.35)',
                    }}
                  >
                    <Loader2 size={13} className="animate-spin" style={{ color: accentColor }} />
                    Waiting for authorization on the Real Debrid website…
                  </div>
                </div>
              )}

              {/* ── SUCCESS ── */}
              {step === 'success' && (
                <div className="flex flex-col items-center gap-4 py-6">
                  <div
                    className="flex items-center justify-center rounded-full"
                    style={{ width: 56, height: 56, background: 'rgba(0,230,118,0.12)' }}
                  >
                    <CheckCircle2 size={28} className="text-success" />
                  </div>
                  <div className="text-center">
                    <p className="text-white font-bold" style={{ fontSize: 'clamp(15px,1vw,18px)' }}>
                      Authentication successful!
                    </p>
                    <p className="text-white/35 mt-1" style={{ fontSize: 'clamp(12px,0.72vw,13px)' }}>
                      Your {label} account is now connected.
                    </p>
                  </div>
                </div>
              )}

              {/* ── ERROR ── */}
              {step === 'error' && (
                <div className="flex flex-col gap-4">
                  <div className="flex flex-col items-center gap-3 py-4">
                    <div
                      className="flex items-center justify-center rounded-full"
                      style={{ width: 52, height: 52, background: 'rgba(233,69,96,0.12)' }}
                    >
                      <AlertCircle size={26} className="text-danger" />
                    </div>
                    <p className="text-white/50 text-center leading-relaxed" style={{ fontSize: 'clamp(12px,0.75vw,14px)' }}>
                      {errorMsg}
                    </p>
                  </div>
                  <button
                    onClick={handleRetry}
                    className="w-full flex items-center justify-center gap-2 rounded-card font-semibold text-white/70 border border-white/[0.10] transition-all duration-150 cursor-pointer hover:text-white hover:bg-white/[0.06]"
                    style={{
                      padding: 'clamp(10px,1vh,14px)',
                      fontSize: 'clamp(13px,0.82vw,15px)',
                      background: 'rgba(255,255,255,0.03)',
                    }}
                  >
                    Try Again
                  </button>
                </div>
              )}

            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
