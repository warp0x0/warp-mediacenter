import { useState } from 'react'

export default function GeneralSettings() {
  const [quality, setQuality] = useState('1080p')
  const [cacheHours, setCacheHours] = useState(24)
  const [refreshMinutes, setRefreshMinutes] = useState(60)

  return (
    <div style={{ gap: 'clamp(10px, 0.73vw, 16px)' }}>
      <div className="flex items-center justify-between">
        <label className="text-fg-white" style={{ fontSize: 'var(--body-size)' }}>Preferred Quality</label>
        <select
          value={quality}
          onChange={(e) => setQuality(e.target.value)}
          className="bg-white/5 text-fg-primary border border-white/10 rounded-input px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] text-body cursor-pointer focus:outline-none focus:border-accent"
        >
          <option value="720p">720p</option>
          <option value="1080p">1080p</option>
          <option value="2160p">4K</option>
        </select>
      </div>

      <div className="flex items-center justify-between">
        <label className="text-fg-white" style={{ fontSize: 'var(--body-size)' }}>Image Cache (hours)</label>
        <input
          type="number"
          value={cacheHours}
          onChange={(e) => setCacheHours(Number(e.target.value))}
          className="w-[clamp(80px,6vw,120px)] input-field text-body text-center"
          min={1}
          max={168}
        />
      </div>

      <div className="flex items-center justify-between">
        <label className="text-fg-white" style={{ fontSize: 'var(--body-size)' }}>Refresh Interval (min)</label>
        <input
          type="number"
          value={refreshMinutes}
          onChange={(e) => setRefreshMinutes(Number(e.target.value))}
          className="w-[clamp(80px,6vw,120px)] input-field text-body text-center"
          min={5}
          max={1440}
        />
      </div>

      <button
        className="btn-danger cursor-pointer"
        onClick={() => {
          try { localStorage.clear() } catch { /* noop */ }
        }}
      >
        Clear Local Cache
      </button>

      <div className="border-t border-white/5 pt-[clamp(8px,0.83vw,16px)]">
        <p className="text-fg-muted mb-[clamp(4px,0.31vw,8px)]"
           style={{ fontSize: 'var(--subtitle-size)' }}>
          Keyboard Shortcuts
        </p>
        <div className="space-y-[clamp(2px,0.16vw,4px)]">
          {[
            ['/', 'Toggle search'],
            ['?', 'Help'],
            ['f', 'Fullscreen'],
            ['Esc', 'Go back'],
            ['← → ↑ ↓', 'Navigate cards'],
            ['Enter', 'Open detail'],
          ].map(([key, desc]) => (
            <div key={key} className="flex justify-between" style={{ fontSize: 'var(--subtitle-size)' }}>
              <kbd className="text-fg-muted font-mono">{key}</kbd>
              <span className="text-fg-muted">{desc}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
