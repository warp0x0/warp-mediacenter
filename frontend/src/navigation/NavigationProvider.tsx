import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react'
import type { Dispatch, ReactNode, SetStateAction } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'

type Direction = 'up' | 'down' | 'left' | 'right'
type NavMode = 'page' | 'menu' | 'scroll-rail'

export interface NavContextMenuItem {
  key: string
  label: string
  icon?: ReactNode
  disabled?: boolean
  destructive?: boolean
  onSelect: () => void | Promise<void>
}

interface RegisteredNavItem {
  id: string
  element: HTMLElement
  onEnter?: () => void
  getContextMenu?: () => NavContextMenuItem[] | null
}

interface ContextMenuState {
  open: boolean
  anchorId: string | null
  items: NavContextMenuItem[]
  selectedIndex: number
  position: { top: number; left: number }
}

interface ScrollRailState {
  active: boolean
  container: HTMLElement | null
  sourceId: string | null
  thumbPercent: number
}

interface ScrollSnapshot {
  index: number
  top: number
  left: number
}

interface RouteMemory {
  pathname: string
  navId: string
  scroll: ScrollSnapshot[]
}

interface NavigationContextValue {
  activeId: string | null
  registerItem: (item: RegisteredNavItem) => () => void
  focusNavItem: (id: string, opts?: { scroll?: boolean; behavior?: ScrollBehavior }) => boolean
  rememberFocusForNavigation: (id?: string | null) => void
  openContextMenuForItem: (id: string, point?: { x: number; y: number }) => boolean
  openMenuForItem: (id: string, point?: { x: number; y: number }) => boolean
  closeContextMenu: () => void
}

const LONG_PRESS_MS = 600
const MENU_WIDTH = 220

const NavigationContext = createContext<NavigationContextValue | null>(null)

function attrEscape(value: string): string {
  return typeof CSS !== 'undefined' && typeof CSS.escape === 'function'
    ? CSS.escape(value)
    : value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')
}

function isVisible(el: HTMLElement): boolean {
  const style = window.getComputedStyle(el)
  if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return false
  const rect = el.getBoundingClientRect()
  return rect.width > 0 && rect.height > 0
}

function isEditableTarget(target: EventTarget | null): boolean {
  if (!target) return false
  const el = target as HTMLElement
  if ((el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) && el.readOnly) return false
  return el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.isContentEditable
}

function getNavItems(): HTMLElement[] {
  return Array.from(document.querySelectorAll<HTMLElement>('[data-nav-item]'))
    .filter((el) => !el.hasAttribute('data-nav-disabled') && !(el as HTMLButtonElement).disabled && (el.tabIndex ?? 0) >= 0 && isVisible(el))
}

function getNavId(el: HTMLElement | null): string | null {
  return el?.getAttribute('data-nav-id') ?? null
}

function focusElement(el: HTMLElement, scroll = true, behavior: ScrollBehavior = 'smooth') {
  const navId = el.getAttribute('data-nav-id')
  console.debug('[nav] focusElement', navId, 'scroll=', scroll, 'behavior=', behavior)
  el.focus({ preventScroll: true })
  if (!scroll) return

  // Snap-aware scrolling: on scroll-snap-type: mandatory containers (Movies/Shows),
  // scrollIntoView({block:'center'}) crosses section boundaries and snap yanks
  // the viewport to a different section. Instead, scroll to the section boundary
  // (the snap position) and center the card within its horizontal ribbon only.
  const container = el.closest<HTMLElement>('[data-nav-scroll-container]')
  const snapType = container ? getComputedStyle(container).scrollSnapType : ''
  if (snapType && snapType !== 'none') {
    const section = el.closest<HTMLElement>('[data-nav-section]')
    if (section && container) {
      const sectionRect = section.getBoundingClientRect()
      const containerRect = container.getBoundingClientRect()
      container.scrollTo({ top: container.scrollTop + (sectionRect.top - containerRect.top), behavior })
    }
    const ribbon = el.closest<HTMLElement>('[data-nav-ribbon]')
    if (ribbon) {
      const rect = el.getBoundingClientRect()
      const ribbonRect = ribbon.getBoundingClientRect()
      const targetLeft = ribbon.scrollLeft + (rect.left - ribbonRect.left) - (ribbonRect.width / 2 - rect.width / 2)
      ribbon.scrollTo({ left: Math.max(0, targetLeft), behavior })
    }
    return
  }

  el.scrollIntoView({ behavior, block: 'center', inline: 'center' })
}

function scrollContainers(): HTMLElement[] {
  return Array.from(document.querySelectorAll<HTMLElement>('[data-nav-scroll-container], [data-nav-ribbon]'))
}

function captureScrollSnapshots(): ScrollSnapshot[] {
  return scrollContainers().map((el, index) => ({ index, top: el.scrollTop, left: el.scrollLeft }))
}

function restoreScrollSnapshots(snapshots: ScrollSnapshot[]) {
  const containers = scrollContainers()
  snapshots.forEach(({ index, top, left }) => {
    const el = containers[index]
    if (el) el.scrollTo({ top, left, behavior: 'auto' })
  })
}

let pendingRestore: { frames: number } | null = null

function restoreFocusedElement(el: HTMLElement, snapshots: ScrollSnapshot[]) {
  if (pendingRestore) pendingRestore.frames = 0
  let focused = false
  const run = (remaining: number) => {
    if (!el.isConnected) return
    // Re-assert captured scroll positions every frame to counteract reflow /
    // image-load shifts that move section boundaries after remount.
    restoreScrollSnapshots(snapshots)
    // Focus only once (first frame). Re-focusing every frame re-triggers the
    // card's onFocus handler 6×, each firing a smooth scrollIntoView that
    // races the instant snapshot restore and fights scroll-snap.
    if (!focused) {
      el.focus({ preventScroll: true })
      focused = true
    }
    if (remaining > 0) {
      pendingRestore = { frames: remaining - 1 }
      requestAnimationFrame(() => run(remaining - 1))
    } else {
      pendingRestore = null
    }
  }
  run(6)
}

function getScrollPercent(container: HTMLElement | null): number {
  if (!container) return 0
  const max = Math.max(1, container.scrollHeight - container.clientHeight)
  return Math.max(0, Math.min(1, container.scrollTop / max))
}

function center(el: HTMLElement) {
  const rect = el.getBoundingClientRect()
  return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2, rect }
}

function getSequentialNeighbor(active: HTMLElement, direction: Direction): HTMLElement | null {
  const group = active.getAttribute('data-nav-group')
  const axis = active.getAttribute('data-nav-axis')
  if (!group || (axis !== 'horizontal' && axis !== 'vertical')) return null
  if (axis === 'horizontal' && direction !== 'left' && direction !== 'right') return null
  if (axis === 'vertical' && direction !== 'up' && direction !== 'down') return null
  const items = getNavItems().filter((el) => el.getAttribute('data-nav-group') === group)
  const idx = items.indexOf(active)
  if (idx === -1) return null
  if (direction === 'right' || direction === 'down') return items[idx + 1] ?? null
  return items[idx - 1] ?? null
}

function findByRole(sectionId: string | null, role: string): HTMLElement | null {
  if (!sectionId) return null
  return document.querySelector<HTMLElement>(`[data-nav-section-id="${attrEscape(sectionId)}"][data-nav-role="${role}"]`)
}

function findFirstCard(sectionId: string | null): HTMLElement | null {
  if (!sectionId) return null
  return getNavItems().find(
    (el) => el.getAttribute('data-nav-section-id') === sectionId && el.getAttribute('data-nav-kind') === 'card',
  ) ?? null
}

function findNextSection(startSectionId: string | null, direction: 'next' | 'prev'): string | null {
  if (!startSectionId) return null
  const sections = Array.from(document.querySelectorAll<HTMLElement>('[data-nav-section]'))
  const ids = sections.map((el) => el.getAttribute('data-nav-section-id')).filter((id): id is string => Boolean(id))
  const idx = ids.indexOf(startSectionId)
  if (idx === -1) return null
  return direction === 'next' ? (ids[idx + 1] ?? null) : (ids[idx - 1] ?? null)
}

function findWidgetVertical(active: HTMLElement, direction: Direction): HTMLElement | null {
  const sectionId = active.getAttribute('data-nav-section-id')
  const kind = active.getAttribute('data-nav-kind')
  const role = active.getAttribute('data-nav-role')

  if (kind === 'card' && direction === 'up') {
    const { x } = center(active)
    if (x < window.innerWidth / 2) {
      return findByRole(sectionId, 'play-trailer') ?? findByRole(sectionId, 'more-info')
    }
    return findByRole(sectionId, 'see-more') ?? findByRole(sectionId, 'more-info')
  }

  if (kind === 'card' && direction === 'down') {
    const nextSection = findNextSection(sectionId, 'next')
    return findByRole(nextSection, 'play-trailer') ?? findFirstCard(nextSection)
  }

  if ((role === 'play-trailer' || role === 'more-info' || role === 'see-more') && direction === 'down') {
    return findFirstCard(sectionId)
  }

  return null
}

function firstInGroup(group: string): HTMLElement | null {
  return getNavItems().find((el) => el.getAttribute('data-nav-group') === group) ?? null
}

function findDetailVertical(active: HTMLElement, direction: Direction): HTMLElement | null {
  if (direction !== 'down' && direction !== 'up') return null
  const group = active.getAttribute('data-nav-group')
  if (!group?.startsWith('detail-')) return null

  if (direction === 'down') {
    if (group === 'detail-actions') {
      return firstInGroup('detail-seasons') ?? firstInGroup('detail-providers') ?? firstInGroup('detail-local-sources')
    }
    if (group === 'detail-seasons') return firstInGroup('detail-episodes') ?? firstInGroup('detail-providers') ?? firstInGroup('detail-local-sources')
    if (group === 'detail-episodes') {
      const nextEpisode = getSequentialNeighbor(active, 'down')
      return nextEpisode ?? firstInGroup('detail-providers') ?? firstInGroup('detail-local-sources')
    }
    if (group === 'detail-providers') return firstInGroup('detail-local-sources')
  }

  if (direction === 'up') {
    if (group === 'detail-local-sources') {
      const prevLocalSource = getSequentialNeighbor(active, 'up')
      return prevLocalSource ?? firstInGroup('detail-providers') ?? firstInGroup('detail-episodes') ?? firstInGroup('detail-seasons') ?? firstInGroup('detail-actions')
    }
    if (group === 'detail-providers') return firstInGroup('detail-episodes') ?? firstInGroup('detail-seasons') ?? firstInGroup('detail-actions')
    if (group === 'detail-episodes') {
      const prevEpisode = getSequentialNeighbor(active, 'up')
      return prevEpisode ?? firstInGroup('detail-seasons') ?? firstInGroup('detail-actions')
    }
    if (group === 'detail-seasons') return firstInGroup('detail-actions')
  }

  return null
}

function spatialSearch(active: HTMLElement, direction: Direction): HTMLElement | null {
  const activeCenter = center(active)
  const candidates = getNavItems().filter((el) => {
    if (el === active) return false
    const candidateCenter = center(el)
    switch (direction) {
      case 'right': return candidateCenter.x > activeCenter.x + 4
      case 'left': return candidateCenter.x < activeCenter.x - 4
      case 'down': return candidateCenter.y > activeCenter.y + 4
      case 'up': return candidateCenter.y < activeCenter.y - 4
    }
  })
  if (!candidates.length) return null
  const isHorizontal = direction === 'left' || direction === 'right'
  return candidates.reduce((best, el) => {
    const c = center(el)
    const b = center(best)
    const primary = isHorizontal ? Math.abs(c.x - activeCenter.x) : Math.abs(c.y - activeCenter.y)
    const secondary = isHorizontal ? Math.abs(c.y - activeCenter.y) : Math.abs(c.x - activeCenter.x)
    const bestPrimary = isHorizontal ? Math.abs(b.x - activeCenter.x) : Math.abs(b.y - activeCenter.y)
    const bestSecondary = isHorizontal ? Math.abs(b.y - activeCenter.y) : Math.abs(b.x - activeCenter.x)
    return primary + secondary * 3 < bestPrimary + bestSecondary * 3 ? el : best
  })
}

function findNextFocus(active: HTMLElement, direction: Direction): HTMLElement | null {
  // Explicit up-target override: elements inside a [data-nav-up-target] container
  // redirect Up to the specified nav-id, bypassing spatial search.
  if (direction === 'up') {
    const upContainer = active.closest<HTMLElement>('[data-nav-up-target]')
    if (upContainer) {
      const targetId = upContainer.getAttribute('data-nav-up-target')
      if (targetId) {
        const target = document.querySelector<HTMLElement>(`[data-nav-id="${attrEscape(targetId)}"]`)
        if (target && isVisible(target)) return target
      }
    }
  }
  const detail = findDetailVertical(active, direction)
  if (detail) return detail
  const widget = findWidgetVertical(active, direction)
  if (widget) return widget
  const sequential = getSequentialNeighbor(active, direction)
  if (sequential) return sequential
  const axis = active.getAttribute('data-nav-axis')
  const group = active.getAttribute('data-nav-group')
  // If an item declares row/column membership, do not leak horizontal or
  // vertical movement to arbitrary spatial matches when the row/column ends.
  if (group && axis === 'horizontal' && (direction === 'left' || direction === 'right')) return null
  if (group && axis === 'vertical' && (direction === 'up' || direction === 'down')) return null
  return spatialSearch(active, direction)
}

function shouldEnterScrollRail(active: HTMLElement): boolean {
  const rect = active.getBoundingClientRect()
  const centerX = rect.left + rect.width / 2
  if (centerX < window.innerWidth * 0.72) return false
  const container = active.closest<HTMLElement>('[data-nav-scroll-container]')
    ?? document.querySelector<HTMLElement>('[data-nav-scroll-container]')
  if (!container) return false
  return container.scrollHeight > container.clientHeight + 8
}

function nearestVisibleNavItemFromViewport(): HTMLElement | null {
  const viewportX = window.innerWidth * 0.72
  const viewportY = window.innerHeight / 2
  const visible = getNavItems().filter((el) => {
    const rect = el.getBoundingClientRect()
    return rect.bottom >= 0 && rect.top <= window.innerHeight && rect.right >= 0 && rect.left <= window.innerWidth
  })
  if (!visible.length) return null
  return visible.reduce((best, el) => {
    const c = center(el)
    const b = center(best)
    const score = Math.abs(c.y - viewportY) * 2 + Math.abs(c.x - viewportX)
    const bestScore = Math.abs(b.y - viewportY) * 2 + Math.abs(b.x - viewportX)
    return score < bestScore ? el : best
  })
}

function computeMenuPosition(anchor: HTMLElement | null, point?: { x: number; y: number }, itemCount = 3) {
  const menuHeight = itemCount * 44 + 16
  let top = point?.y ?? 0
  let left = point?.x ?? 0

  if (!point && anchor) {
    const rect = anchor.getBoundingClientRect()
    const rawRadius = parseFloat(getComputedStyle(anchor).getPropertyValue('--card-radius')) || 0
    top = rect.top
    left = rect.right - rawRadius
  }

  if (top + menuHeight > window.innerHeight - 8) top = Math.max(8, window.innerHeight - menuHeight - 8)
  if (left + MENU_WIDTH > window.innerWidth - 8) left = Math.max(8, window.innerWidth - MENU_WIDTH - 8)
  if (left < 8) left = 8
  if (top < 8) top = 8
  return { top, left }
}

export function NavigationProvider({ children, onToggleHelp }: { children: ReactNode; onToggleHelp?: () => void }) {
  const navigate = useNavigate()
  const location = useLocation()
  const registryRef = useRef(new Map<string, RegisteredNavItem>())
  const [activeId, setActiveId] = useState<string | null>(null)
  const activeIdRef = useRef<string | null>(null)
  const [mode, setMode] = useState<NavMode>('page')
  const [scrollRail, setScrollRail] = useState<ScrollRailState>({ active: false, container: null, sourceId: null, thumbPercent: 0 })
  const routeMemoryRef = useRef<RouteMemory | null>(null)
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const longPressFired = useRef(false)
  // Set by the keydown handler when Enter is consumed inside the context menu
  // (menu mode). onKeyUp checks this to avoid re-firing onEnter/click on the
  // anchor element — which would re-open the dropdown or navigate away.
  const menuEnterConsumed = useRef(false)
  const [contextMenu, setContextMenu] = useState<ContextMenuState>({
    open: false,
    anchorId: null,
    items: [],
    selectedIndex: 0,
    position: { top: 0, left: 0 },
  })

  const setActive = useCallback((id: string | null) => {
    if (id !== activeIdRef.current) console.debug('[nav] setActive', id)
    activeIdRef.current = id
    setActiveId(id)
  }, [])

  const registerItem = useCallback((item: RegisteredNavItem) => {
    registryRef.current.set(item.id, item)
    requestAnimationFrame(() => {
      // Only skip initial-focus if there's route memory for the CURRENT page
      // (tryRestore will handle focus in that case). Memory for a DIFFERENT
      // page must NOT block initial-focus — otherwise pages reached via
      // mouse-click navigation (e.g. "See More" → CatalogBrowse) never
      // auto-focus their data-nav-initial element, leaving activeId=null.
      const memory = routeMemoryRef.current
      if (memory && memory.pathname === location.pathname) {
        console.debug('[nav] registerItem SKIP initial-focus (routeMemory for current page)', item.id)
        return
      }
      if (!activeIdRef.current && item.element.hasAttribute('data-nav-initial') && isVisible(item.element)) {
        console.debug('[nav] registerItem initial-focus →', item.id)
        focusElement(item.element, false)
        setActive(item.id)
      }
    })
    return () => {
      const current = registryRef.current.get(item.id)
      if (current?.element === item.element) registryRef.current.delete(item.id)
    }
  }, [setActive, location.pathname])

  const rememberSourceFocus = useCallback((id: string) => {
    const existing = routeMemoryRef.current
    if (existing && existing.pathname === location.pathname && existing.navId === id) return
    routeMemoryRef.current = { pathname: location.pathname, navId: id, scroll: captureScrollSnapshots() }
    console.debug('[nav] rememberSourceFocus', id, 'pathname=', location.pathname)
  }, [location.pathname])

  const getNavElement = useCallback((id: string): HTMLElement | null => {
    const registered = registryRef.current.get(id)?.element
    if (registered?.isConnected) return registered
    return document.querySelector<HTMLElement>(`[data-nav-id="${attrEscape(id)}"]`)
  }, [])

  const focusNavItem = useCallback((id: string, opts?: { scroll?: boolean; behavior?: ScrollBehavior }) => {
    const el = getNavElement(id)
    if (!el || !isVisible(el)) {
      console.debug('[nav] focusNavItem FAIL (not found or not visible)', id)
      return false
    }
    console.debug('[nav] focusNavItem →', id, 'scroll=', opts?.scroll ?? true)
    focusElement(el, opts?.scroll ?? true, opts?.behavior ?? 'smooth')
    setActive(id)
    return true
  }, [getNavElement, setActive])

  const rememberFocusForNavigation = useCallback((id?: string | null) => {
    const navId = id ?? activeIdRef.current ?? getNavId(document.activeElement as HTMLElement | null)
    if (navId) rememberSourceFocus(navId)
  }, [rememberSourceFocus])

  const closeContextMenu = useCallback(() => {
    const anchorId = contextMenu.anchorId
    setContextMenu((prev) => ({ ...prev, open: false, items: [], selectedIndex: 0 }))
    setMode('page')
    if (anchorId) requestAnimationFrame(() => focusNavItem(anchorId, { scroll: false }))
  }, [contextMenu.anchorId, focusNavItem])

  const openContextMenuForItem = useCallback((id: string, point?: { x: number; y: number }) => {
    const item = registryRef.current.get(id)
    const items = item?.getContextMenu?.() ?? null
    if (!item || !items?.length) return false
    setActive(id)
    setContextMenu({
      open: true,
      anchorId: id,
      items,
      selectedIndex: -1,
      position: computeMenuPosition(item.element, point, items.length),
    })
    setMode('menu')
    return true
  }, [setActive])

  // Like openContextMenuForItem but opens with the first item pre-selected.
  // Used by dropdown buttons (e.g. Sort) where Enter should immediately show
  // a selection. NOT used by long-press context menus on cards, where the
  // first up/down arrow key press moves focus to the items.
  const openMenuForItem = useCallback((id: string, point?: { x: number; y: number }) => {
    const item = registryRef.current.get(id)
    const items = item?.getContextMenu?.() ?? null
    if (!item || !items?.length) return false
    setActive(id)
    setContextMenu({
      open: true,
      anchorId: id,
      items,
      selectedIndex: 0,
      position: computeMenuPosition(item.element, point, items.length),
    })
    setMode('menu')
    return true
  }, [setActive])

  const value = useMemo<NavigationContextValue>(() => ({
    activeId,
    registerItem,
    focusNavItem,
    rememberFocusForNavigation,
    openContextMenuForItem,
    openMenuForItem,
    closeContextMenu,
  }), [activeId, registerItem, focusNavItem, rememberFocusForNavigation, openContextMenuForItem, openMenuForItem, closeContextMenu])

  useEffect(() => {
    console.debug('[nav] ROUTE-CHANGE', location.pathname, 'memory=', routeMemoryRef.current ? { pathname: routeMemoryRef.current.pathname, navId: routeMemoryRef.current.navId } : null)
    setActive(null)
    setMode('page')
    setScrollRail({ active: false, container: null, sourceId: null, thumbPercent: 0 })
    const memory = routeMemoryRef.current
    if (!memory || memory.pathname !== location.pathname) {
      console.debug('[nav] ROUTE-CHANGE no restore (memory null or pathname mismatch)')
      // No memory to restore — but don't leave focus on <body>. Schedule a
      // deferred fallback that focuses the data-nav-initial element (or nearest
      // visible nav item) once the new page's DOM is committed. Without this,
      // pages reached without prior rememberSourceFocus (e.g. clicking "See
      // More" which navigates to a new page) start with no focus target.
      requestAnimationFrame(() => {
        if (activeIdRef.current) return  // something else already focused
        const initial = document.querySelector<HTMLElement>('[data-nav-initial]')
        if (initial && isVisible(initial)) {
          const id = getNavId(initial)
          console.debug('[nav] ROUTE-CHANGE fallback initial-focus →', id)
          if (id) focusNavItem(id, { scroll: false })
        } else {
          const fallback = nearestVisibleNavItemFromViewport() ?? getNavItems()[0]
          const id = getNavId(fallback)
          console.debug('[nav] ROUTE-CHANGE fallback nearest →', id)
          if (id) focusNavItem(id, { scroll: false })
        }
      })
      return
    }
    const memoryRef = memory
    let attempts = 0
    const tryRestore = () => {
      const el = getNavElement(memoryRef.navId)
      if (el && isVisible(el)) {
        console.debug('[nav] tryRestore SUCCESS', memoryRef.navId, 'attempt=', attempts)
        restoreFocusedElement(el, memoryRef.scroll)
        setActive(memoryRef.navId)
        routeMemoryRef.current = null
        return
      }
      attempts += 1
      if (attempts < 30) {
        if (attempts === 1 || attempts % 10 === 0) console.debug('[nav] tryRestore retry', attempts, 'navId=', memoryRef.navId, 'elExists=', !!el, 'visible=', el ? isVisible(el) : false)
        requestAnimationFrame(tryRestore)
      } else {
        console.debug('[nav] tryRestore GIVEUP after', attempts, '— using fallback')
        routeMemoryRef.current = null
        const fallback = nearestVisibleNavItemFromViewport() ?? getNavItems()[0]
        const fallbackId = getNavId(fallback)
        if (fallbackId) focusNavItem(fallbackId)
      }
    }
    tryRestore()
  }, [location.pathname, getNavElement, setActive])

  useEffect(() => {
    const clearLongPress = () => {
      if (longPressTimer.current) clearTimeout(longPressTimer.current)
      longPressTimer.current = null
    }

    const onPointerDown = (e: PointerEvent) => {
      const item = (e.target as HTMLElement).closest<HTMLElement>('[data-nav-item]')
      const id = getNavId(item)
      if (!id) return
      const isBack = item?.getAttribute('data-nav-role') === 'back'
      console.debug('[nav] pointerdown', id, 'isBack=', isBack)
      if (isBack) return
      setActive(id)
      rememberSourceFocus(id)
      item?.focus({ preventScroll: true })
    }

    const onMouseDown = (e: MouseEvent) => {
      const item = (e.target as HTMLElement).closest<HTMLElement>('[data-nav-item]')
      if (item?.getAttribute('data-nav-role') === 'back') {
        console.debug('[nav] mousedown preventDefault (back button)')
        e.preventDefault()
      }
    }

    const onFocusIn = (e: FocusEvent) => {
      const item = (e.target as HTMLElement).closest<HTMLElement>('[data-nav-item]')
      const id = getNavId(item)
      if (id) {
        const isBack = item?.getAttribute('data-nav-role') === 'back'
        if (isBack) {
          console.debug('[nav] focusin SKIP (back button)', id)
          return
        }
        console.debug('[nav] focusin', id, 'tag=', (e.target as HTMLElement)?.tagName)
        setActive(id)
      } else if (e.target === document.body || e.target === document.documentElement) {
        console.debug('[nav] focusin → body/html, clearing activeId')
        setActive(null)
      }
    }

    const onContextMenu = (e: MouseEvent) => {
      const item = (e.target as HTMLElement).closest<HTMLElement>('[data-nav-item]')
      const id = getNavId(item)
      if (!id) return
      if (openContextMenuForItem(id, { x: e.clientX, y: e.clientY })) {
        e.preventDefault()
        e.stopPropagation()
      }
    }

    const onKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement
      if (isEditableTarget(target) && e.key !== 'Escape') return

      if (contextMenu.open || mode === 'menu') {
        if (!['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Enter', ' ', 'Escape', 'Backspace'].includes(e.key)) return
        e.preventDefault()
        e.stopImmediatePropagation()
        if (e.key === 'Escape' || e.key === 'Backspace' || e.key === 'ArrowLeft') {
          closeContextMenu()
          return
        }
        if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
          setContextMenu((prev) => {
            if (!prev.items.length) return prev
            if (prev.selectedIndex < 0) {
              return { ...prev, selectedIndex: e.key === 'ArrowDown' ? 0 : prev.items.length - 1 }
            }
            const delta = e.key === 'ArrowDown' ? 1 : -1
            return { ...prev, selectedIndex: (prev.selectedIndex + delta + prev.items.length) % prev.items.length }
          })
          return
        }
        if (e.key === 'Enter' || e.key === ' ') {
          if (contextMenu.selectedIndex < 0) return
          const item = contextMenu.items[contextMenu.selectedIndex]
          if (item && !item.disabled) {
            menuEnterConsumed.current = true
            void item.onSelect()
            closeContextMenu()
          }
        }
        return
      }

      if (mode === 'scroll-rail') {
        if (!['ArrowUp', 'ArrowDown', 'ArrowLeft', 'Escape', 'Backspace'].includes(e.key)) return
        e.preventDefault()
        e.stopImmediatePropagation()
        if (e.key === 'ArrowUp' || e.key === 'ArrowDown') {
          scrollRail.container?.scrollBy({ top: e.key === 'ArrowDown' ? 260 : -260, behavior: 'smooth' })
          return
        }
        setMode('page')
        setScrollRail({ active: false, container: null, sourceId: null, thumbPercent: 0 })
        const nearest = nearestVisibleNavItemFromViewport()
          ?? (scrollRail.sourceId ? getNavElement(scrollRail.sourceId) : null)
          ?? getNavItems()[0]
        if (nearest) {
          const id = getNavId(nearest)
          if (id) focusNavItem(id)
        }
        return
      }

      if ((e.key === 'Enter' || e.key === ' ') && !e.repeat) {
        e.preventDefault()
        e.stopImmediatePropagation()
        longPressFired.current = false
        clearLongPress()
        longPressTimer.current = setTimeout(() => {
          longPressFired.current = true
          const id = activeIdRef.current ?? getNavId(document.activeElement as HTMLElement | null)
          if (id) openContextMenuForItem(id)
        }, LONG_PRESS_MS)
        return
      }

      if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
        e.preventDefault()
        e.stopImmediatePropagation()
        const direction = e.key.replace('Arrow', '').toLowerCase() as Direction
        const focused = (document.activeElement as HTMLElement | null)?.closest<HTMLElement>('[data-nav-item]') ?? null
        const activeEl = (activeIdRef.current ? getNavElement(activeIdRef.current) : null) ?? focused
        console.debug('[nav] ARROW', direction, 'activeId=', activeIdRef.current, 'activeEl=', activeEl?.getAttribute('data-nav-id') ?? 'null', 'docActive=', (document.activeElement as HTMLElement)?.tagName, 'focused=', focused?.getAttribute('data-nav-id') ?? 'null')
        if (!activeEl || activeEl === document.body) {
          const first = nearestVisibleNavItemFromViewport() ?? getNavItems()[0]
          const id = getNavId(first)
          console.debug('[nav] ARROW fallback →', id)
          if (id) focusNavItem(id)
          return
        }
        const next = findNextFocus(activeEl, direction)
        if (next) {
          const id = getNavId(next)
          console.debug('[nav] ARROW next →', id)
          if (id) focusNavItem(id)
          return
        }
        console.debug('[nav] ARROW no next found')
        if (direction === 'right' && shouldEnterScrollRail(activeEl)) {
          const container = activeEl.closest<HTMLElement>('[data-nav-scroll-container]')
            ?? document.querySelector<HTMLElement>('[data-nav-scroll-container]')
            ?? document.scrollingElement as HTMLElement | null
          setMode('scroll-rail')
          setScrollRail({ active: true, container, sourceId: getNavId(activeEl), thumbPercent: getScrollPercent(container) })
        }
        return
      }

      if (e.key === 'Backspace' || e.key === 'Escape' || e.key === 'BrowserBack') {
        console.debug('[nav] BACK key', e.key, 'activeId=', activeIdRef.current)
        e.preventDefault()
        e.stopImmediatePropagation()
        navigate(-1)
        return
      }

      if (e.key === '?' && onToggleHelp) {
        e.preventDefault()
        onToggleHelp()
      }
    }

    const onKeyUp = (e: KeyboardEvent) => {
      if (e.key !== 'Enter' && e.key !== ' ') return
      if (isEditableTarget(e.target)) return
      e.preventDefault()
      e.stopImmediatePropagation()
      clearLongPress()
      // If the keydown was consumed by the context menu (selecting a menu item),
      // skip onEnter/click — otherwise onEnter re-opens the dropdown or fires
      // on the element that received focus after closeContextMenu.
      if (menuEnterConsumed.current) {
        menuEnterConsumed.current = false
        return
      }
      if (longPressFired.current) return
      const id = activeIdRef.current ?? getNavId(document.activeElement as HTMLElement | null)
      const item = id ? registryRef.current.get(id) : null
      console.debug('[nav] KEYUP Enter/Space', 'activeId=', activeIdRef.current, 'resolvedId=', id, 'hasOnEnter=', !!item?.onEnter)
      if (item?.onEnter) item.onEnter()
      else (document.activeElement as HTMLElement | null)?.click()
    }

    window.addEventListener('keydown', onKeyDown, true)
    window.addEventListener('keyup', onKeyUp, true)
    window.addEventListener('pointerdown', onPointerDown, true)
    window.addEventListener('mousedown', onMouseDown, true)
    window.addEventListener('focusin', onFocusIn, true)
    window.addEventListener('contextmenu', onContextMenu, true)
    return () => {
      clearLongPress()
      window.removeEventListener('keydown', onKeyDown, true)
      window.removeEventListener('keyup', onKeyUp, true)
      window.removeEventListener('pointerdown', onPointerDown, true)
      window.removeEventListener('mousedown', onMouseDown, true)
      window.removeEventListener('focusin', onFocusIn, true)
      window.removeEventListener('contextmenu', onContextMenu, true)
    }
  }, [closeContextMenu, contextMenu, focusNavItem, getNavElement, mode, navigate, onToggleHelp, openContextMenuForItem, rememberFocusForNavigation, scrollRail.container, scrollRail.sourceId, setActive])

  useEffect(() => {
    if (!scrollRail.active || !scrollRail.container) return
    let frame = 0
    const container = scrollRail.container
    const update = () => {
      cancelAnimationFrame(frame)
      frame = requestAnimationFrame(() => {
        setScrollRail((prev) => prev.container === container
          ? { ...prev, thumbPercent: getScrollPercent(container) }
          : prev)
      })
    }
    update()
    container.addEventListener('scroll', update, { passive: true })
    window.addEventListener('resize', update)
    return () => {
      cancelAnimationFrame(frame)
      container.removeEventListener('scroll', update)
      window.removeEventListener('resize', update)
    }
  }, [scrollRail.active, scrollRail.container])

  return (
    <NavigationContext.Provider value={value}>
      {children}
      <ContextMenuHost state={contextMenu} setState={setContextMenu} close={closeContextMenu} />
      <ScrollRail active={scrollRail.active} thumbPercent={scrollRail.thumbPercent} />
    </NavigationContext.Provider>
  )
}

function ContextMenuHost({
  state,
  setState,
  close,
}: {
  state: ContextMenuState
  setState: Dispatch<SetStateAction<ContextMenuState>>
  close: () => void
}) {
  if (!state.open) return null
  return (
    <>
      <div className="fixed inset-0 z-[80]" onClick={close} />
      <div
        className="fixed z-[81] bg-bg-panel/95 backdrop-blur-xl border border-white/10 rounded-card shadow-2xl overflow-hidden"
        role="menu"
        style={{ top: state.position.top, left: state.position.left, width: MENU_WIDTH, padding: 6 }}
      >
        {state.items.map((item, idx) => (
          <button
            key={item.key}
            type="button"
            disabled={item.disabled}
            onMouseEnter={() => setState((prev) => ({ ...prev, selectedIndex: idx }))}
            onClick={() => {
              if (item.disabled) return
              void item.onSelect()
              close()
            }}
            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-btn text-left transition-colors cursor-pointer ${
              item.disabled
                ? 'opacity-40 cursor-not-allowed'
                : idx === state.selectedIndex
                  ? item.destructive
                    ? 'bg-red-500/20 text-red-300'
                    : 'bg-white/12 text-fg-white'
                  : item.destructive
                    ? 'hover:bg-red-500/15 text-red-400'
                    : 'hover:bg-white/8 text-fg-white'
            }`}
            style={{ fontSize: 'var(--body-size)' }}
          >
            {item.icon && <span className="shrink-0">{item.icon}</span>}
            <span className="font-medium">{item.label}</span>
          </button>
        ))}
      </div>
    </>
  )
}

function ScrollRail({ active, thumbPercent }: { active: boolean; thumbPercent: number }) {
  if (!active) return null
  const top = `${Math.max(0, Math.min(1, thumbPercent)) * 100}%`
  return (
    <div className="fixed right-2 top-[12vh] bottom-[4vh] z-[70] w-2 rounded-full bg-white/12 overflow-hidden pointer-events-none">
      <div
        className="absolute left-0 right-0 h-24 rounded-full bg-accent shadow-[0_0_16px_rgba(13,178,226,0.55)]"
        style={{ top, transform: 'translateY(-50%)' }}
      />
    </div>
  )
}

export function useNavigation() {
  const ctx = useContext(NavigationContext)
  if (!ctx) throw new Error('useNavigation must be used inside NavigationProvider')
  return ctx
}

export function useNavItem<T extends HTMLElement>(
  id: string,
  config: Omit<RegisteredNavItem, 'id' | 'element'>,
) {
  const { registerItem } = useNavigation()
  const ref = useRef<T | null>(null)

  useEffect(() => {
    const element = ref.current
    if (!element) return
    return registerItem({ id, element, ...config })
  }, [id, config, registerItem])

  return ref
}
