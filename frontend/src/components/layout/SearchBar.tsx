import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, X, Clock } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { apiGet } from '@/lib/api'
import type { SearchResponse } from '@/lib/types'

const HISTORY_KEY = 'warp_search_history'
const MAX_HISTORY = 10

interface SearchBarProps {
  open: boolean
  onClose: () => void
}

export default function SearchBar({ open, onClose }: SearchBarProps) {
  const [query, setQuery] = useState('')
  const [suggestions, setSuggestions] = useState<SearchResponse['results']>([])
  const [history, setHistory] = useState<string[]>(() => {
    try {
      return JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]')
    } catch {
      return []
    }
  })
  const inputRef = useRef<HTMLInputElement | null>(null)
  const debounceRef = useRef<number | undefined>(undefined)
  const navigate = useNavigate()

  useEffect(() => {
    if (open) {
      setQuery('')
      setSuggestions([])
      setTimeout(() => inputRef.current?.focus(), 50)
    }
  }, [open])

  const fetchSuggestions = useCallback(async (q: string) => {
    if (q.length < 2) {
      setSuggestions([])
      return
    }
    try {
      const data = await apiGet<SearchResponse>('/api/v1/search/unified', { q, limit: '8' })
      setSuggestions(data.results)
    } catch {
      setSuggestions([])
    }
  }, [])

  const handleChange = (value: string) => {
    setQuery(value)
    clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => fetchSuggestions(value), 300)
  }

  const saveToHistory = (q: string) => {
    const updated = [q, ...history.filter((h) => h !== q)].slice(0, MAX_HISTORY)
    setHistory(updated)
    localStorage.setItem(HISTORY_KEY, JSON.stringify(updated))
  }

  const executeSearch = (q: string) => {
    if (!q.trim()) return
    saveToHistory(q.trim())
    navigate(`/search?q=${encodeURIComponent(q.trim())}`)
    onClose()
  }

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/40 z-30"
            onClick={onClose}
          />
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="fixed top-0 left-0 right-0 z-40 bg-bg-panel backdrop-blur-xl border-b border-white/10"
          >
            <div className="flex items-center gap-[clamp(8px,0.63vw,14px)] px-[clamp(12px,1.25vw,24px)]"
                 style={{ height: 'var(--title-bar-height)' }}>
              <Search size={18} className="text-fg-muted shrink-0" />
              <input
                ref={inputRef}
                type="text"
                value={query}
                onChange={(e) => handleChange(e.target.value)}
                placeholder="Search movies, shows..."
                className="flex-1 bg-transparent text-body text-fg-primary outline-none placeholder:text-fg-muted"
              />
              <button onClick={onClose} className="text-fg-muted hover:text-fg-primary cursor-pointer">
                <X size={18} />
              </button>
            </div>

            {(suggestions.length > 0 || (history.length > 0 && !query)) && (
              <div className="border-t border-white/5 px-[clamp(8px,0.83vw,16px)] py-[clamp(6px,0.42vw,10px)] max-h-[clamp(200px,25vh,400px)] overflow-y-auto">
                {!query && history.length > 0 && (
                  <div className="space-y-[clamp(2px,0.16vw,4px)]">
                    <p className="text-xs text-fg-muted px-[clamp(6px,0.52vw,12px)] py-[clamp(2px,0.16vw,4px)]">
                      Recent Searches
                    </p>
                    {history.map((h) => (
                      <button
                        key={h}
                        onClick={() => {
                          setQuery(h)
                          executeSearch(h)
                        }}
                        className="w-full flex items-center gap-[clamp(6px,0.52vw,12px)] px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] rounded-btn text-subtitle text-fg-muted hover:text-fg-primary hover:bg-white/6 cursor-pointer"
                      >
                        <Clock size={14} />
                        {h}
                      </button>
                    ))}
                  </div>
                )}

                {suggestions.length > 0 && (
                  <div className="space-y-[clamp(2px,0.16vw,4px)]">
                    {!query && <div className="h-[clamp(4px,0.31vw,8px)]" />}
                    {suggestions.map((item, i) => (
                      <button
                        key={i}
                        onClick={() => {
                          saveToHistory(item.title)
                          navigate(`/search?q=${encodeURIComponent(item.title)}`)
                          onClose()
                        }}
                        className="w-full flex items-center gap-[clamp(8px,0.63vw,14px)] px-[clamp(8px,0.63vw,14px)] py-[clamp(4px,0.31vw,8px)] rounded-btn text-subtitle text-fg-primary hover:bg-white/6 cursor-pointer"
                      >
                        <span className="flex-1 text-left">{item.title}</span>
                        <span className="text-xs text-fg-muted bg-white/8 px-[clamp(4px,0.31vw,8px)] py-[clamp(1px,0.1vw,3px)] rounded-pill">
                          {item.source}
                        </span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
