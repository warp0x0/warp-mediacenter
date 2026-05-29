import { useState } from 'react'
import { Eye, EyeOff, Save } from 'lucide-react'
import { updateSetting } from '@/hooks/useSettings'

const fields = [
  { key: 'tmdb_api_key', label: 'TMDb API Key' },
  { key: 'trakt_client_id', label: 'Trakt Client ID' },
  { key: 'trakt_client_secret', label: 'Trakt Client Secret' },
  { key: 'realdebrid_client_id', label: 'Real Debrid Client ID' },
  { key: 'realdebrid_client_secret', label: 'Real Debrid Client Secret' },
  { key: 'torrent_api_url', label: 'Torrent API URL' },
  { key: 'torrent_api_key', label: 'Torrent API Key' },
]

interface FieldState {
  value: string
  visible: boolean
  saving: boolean
  saved: boolean
}

export default function ApiKeysForm() {
  const [fieldsState, setFieldsState] = useState<Record<string, FieldState>>(
    Object.fromEntries(
      fields.map((f) => [f.key, { value: '', visible: false, saving: false, saved: false }]),
    ),
  )

  async function handleSave(key: string) {
    const st = fieldsState[key]
    setFieldsState((prev) => ({ ...prev, [key]: { ...st, saving: true, saved: false } }))
    try {
      await updateSetting(key, st.value)
      setFieldsState((prev) => ({ ...prev, [key]: { ...st, saving: false, saved: true } }))
      setTimeout(() => {
        setFieldsState((prev) => ({ ...prev, [key]: { ...prev[key], saved: false } }))
      }, 2000)
    } catch {
      setFieldsState((prev) => ({ ...prev, [key]: { ...st, saving: false } }))
    }
  }

  return (
    <div style={{ gap: 'clamp(8px, 0.63vw, 14px)' }}>
      {fields.map(({ key, label }) => {
        const st = fieldsState[key]
        return (
          <div key={key} className="flex items-center gap-[clamp(6px,0.52vw,12px)]">
            <label className="text-fg-muted w-[clamp(120px,10vw,180px)] shrink-0"
                   style={{ fontSize: 'var(--subtitle-size)' }}>
              {label}
            </label>
            <div className="flex-1 flex items-center gap-[clamp(4px,0.31vw,8px)]">
              <input
                type={st.visible ? 'text' : 'password'}
                value={st.value}
                onChange={(e) =>
                  setFieldsState((prev) => ({
                    ...prev,
                    [key]: { ...prev[key], value: e.target.value },
                  }))
                }
                className="flex-1 input-field text-subtitle"
                placeholder="Enter value..."
              />
              <button
                onClick={() =>
                  setFieldsState((prev) => ({
                    ...prev,
                    [key]: { ...prev[key], visible: !prev[key].visible },
                  }))
                }
                className="text-fg-muted hover:text-fg-primary p-[clamp(4px,0.31vw,8px)] cursor-pointer"
              >
                {st.visible ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
              <button
                onClick={() => handleSave(key)}
                disabled={st.saving}
                className="btn-primary text-subtitle px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] cursor-pointer disabled:opacity-50"
              >
                {st.saving ? 'Saving...' : st.saved ? 'Saved' : <Save size={15} />}
              </button>
            </div>
          </div>
        )
      })}
    </div>
  )
}
