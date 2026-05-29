import type { ReactNode } from 'react'

interface SettingsCardProps {
  icon: ReactNode
  title: string
  children: ReactNode
}

export default function SettingsCard({ icon, title, children }: SettingsCardProps) {
  return (
    <div
      className="rounded-card border border-white/[0.07] overflow-hidden"
      style={{ background: 'rgba(255,255,255,0.025)' }}
    >
      {/* Card header */}
      <div
        className="flex items-center gap-3 border-b border-white/[0.07]"
        style={{
          padding: 'clamp(12px,1.1vh,16px) clamp(16px,1.25vw,24px)',
          background: 'rgba(255,255,255,0.02)',
        }}
      >
        <span className="text-accent" style={{ fontSize: 'clamp(16px,1.1vw,20px)' }}>
          {icon}
        </span>
        <h3
          className="text-white/70 font-semibold uppercase tracking-[0.12em]"
          style={{ fontSize: 'clamp(11px,0.65vw,13px)' }}
        >
          {title}
        </h3>
      </div>

      {/* Card body */}
      <div
        className="flex flex-col"
        style={{
          padding: 'clamp(14px,1.4vh,22px) clamp(16px,1.25vw,24px)',
          gap: 'clamp(12px,1.25vw,20px)',
        }}
      >
        {children}
      </div>
    </div>
  )
}
