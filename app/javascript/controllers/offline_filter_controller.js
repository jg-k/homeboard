import { Controller } from "@hotwired/stimulus"

// The service worker caches the problems index with its query string
// stripped, so offline every filtered URL resolves to the same unfiltered
// page. This controller compares the params the server actually applied
// (stamped into `applied`) with the params in the URL. When they diverge
// the page came from cache, and we reproduce the filter, the sort and the
// prev/next navigation client-side.
//
// Online the two always match and every method below no-ops. We do not
// consult navigator.onLine — it stays true under DevTools throttling (see
// offline_climb_form_controller), and the stamp already tells us the one
// thing we need to know: whether this render matches the request.
export default class extends Controller {
  static values = { applied: Object, grades: Array, boardPath: String }
  static targets = ["list", "detail", "navPosition", "navPrev", "navNext"]

  connect() {
    // Frame navigation swaps the detail pane without reconnecting us.
    this.reapply = () => this.apply()
    document.addEventListener("turbo:frame-load", this.reapply)
    this.apply()
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.reapply)
    if (this.navFrame) cancelAnimationFrame(this.navFrame)
  }

  apply() {
    if (!this.hasListTarget) return
    const wanted = this.urlParams()
    if (this.serverAlreadyApplied(wanted)) return

    this.refreshHeaderLinks(wanted)

    const items = Array.from(this.listTarget.querySelectorAll(".problem-link"))
    if (!items.length) return

    const visible = this.sorted(items.filter(i => this.matches(i, wanted)), wanted.sort)
    const shown = new Set(visible)
    for (const item of items) item.style.display = shown.has(item) ? "" : "none"
    for (const item of visible) this.listTarget.appendChild(item)

    this.updateNavigation(visible, wanted)
  }

  // ----- params -----

  urlParams() {
    const p = new URLSearchParams(window.location.search)
    const out = {}
    for (const key of ["filter", "sort", "min_grade", "max_grade", "board_layout_id"]) {
      const value = p.get(key)
      if (value) out[key] = value
    }
    return out
  }

  // A cached render's filter and new-problem links carry the params of the
  // request that was cached, not the ones in the address bar — following
  // them would silently drop the current filter.
  refreshHeaderLinks(params) {
    const query = new URLSearchParams(params)
    for (const link of this.element.querySelectorAll("a[href*='/problems/filter'], a[href*='/problems/new']")) {
      const url = new URL(link.getAttribute("href"), window.location.origin)
      for (const [key, value] of query) {
        if (!url.searchParams.has(key)) url.searchParams.set(key, value)
      }
      link.setAttribute("href", url.pathname + url.search)
    }
  }

  serverAlreadyApplied(wanted) {
    const applied = this.appliedValue || {}
    const keys = new Set([...Object.keys(applied), ...Object.keys(wanted)])
    for (const key of keys) {
      if ((applied[key] || "") !== (wanted[key] || "")) return false
    }
    return true
  }

  // ----- filtering -----

  matches(item, params) {
    if (params.board_layout_id && item.dataset.boardLayoutId !== params.board_layout_id) return false

    const sent = item.dataset.sent === "true"
    if (params.filter === "sent" && !sent) return false
    if (params.filter === "unsent" && sent) return false

    const min = this.gradeIndex(params.min_grade)
    const max = this.gradeIndex(params.max_grade)
    if (min === null && max === null) return true

    // A grade outside the board's system has index -1. The server filters
    // with `where(grade: valid_grades)`, which drops those too.
    const gradeIndex = parseInt(item.dataset.gradeIndex, 10)
    if (gradeIndex < 0) return false
    if (min !== null && gradeIndex < min) return false
    if (max !== null && gradeIndex > max) return false
    return true
  }

  // Null means "no bound". An unrecognised grade is no bound rather than an
  // empty result, matching the server's `if min_index && max_index` guard.
  gradeIndex(grade) {
    if (!grade) return null
    const index = (this.gradesValue || []).indexOf(grade)
    return index === -1 ? null : index
  }

  // ----- sorting -----

  sorted(items, mode) {
    const copy = [...items]
    if (mode === "grade" || mode === "grade_desc") {
      // Problem.by_grade sorts unknown grades to 999, then reverses the
      // whole array for :desc — ties included. Mirror both.
      copy.sort((a, b) => this.gradeRank(a) - this.gradeRank(b))
      if (mode === "grade_desc") copy.reverse()
    } else {
      copy.sort((a, b) => parseInt(b.dataset.createdAt, 10) - parseInt(a.dataset.createdAt, 10))
    }
    return copy
  }

  gradeRank(item) {
    const index = parseInt(item.dataset.gradeIndex, 10)
    return index < 0 ? 999 : index
  }

  // ----- navigation -----

  updateNavigation(visible, params) {
    const frame = this.currentFrame()
    if (!frame) return
    const currentId = parseInt(frame.dataset.problemId, 10)
    if (Number.isNaN(currentId)) return

    const index = visible.findIndex(i => parseInt(i.dataset.problemId, 10) === currentId)

    if (index === -1) {
      // The problem on screen is filtered out. Jump to the first match; its
      // page is pinned, so this resolves from cache offline. The destination
      // is in its own visible set, so it will not bounce again. Never do this
      // mid-edit — it would discard whatever the form is holding.
      const first = visible[0]
      if (first && frame.dataset.editing !== "true") {
        this.visit(this.problemUrl(first.dataset.problemId, params))
      }
      return
    }

    // problem-data rewrites the swipe URLs from its own server-rendered
    // values when it connects, and Stimulus connects on a microtask — after
    // turbo:frame-load but before the next frame. Write last so we win.
    if (this.navFrame) cancelAnimationFrame(this.navFrame)
    this.navFrame = requestAnimationFrame(() => {
      this.writeNav(visible[index - 1], visible[index + 1], index + 1, visible.length, params)
    })
  }

  // Desktop and mobile each render a detail frame and they navigate
  // independently, so prefer whichever one the breakpoint is showing.
  currentFrame() {
    const frames = this.detailTargets
    if (!frames.length) return null
    return frames.find(f => f.getClientRects().length > 0) || frames[0]
  }

  writeNav(prev, next, position, count, params) {
    const prevUrl = prev ? this.problemUrl(prev.dataset.problemId, params) : ""
    const nextUrl = next ? this.problemUrl(next.dataset.problemId, params) : ""

    for (const el of this.navPositionTargets) el.textContent = `${position} / ${count}`
    this.setNavLink(this.navPrevTargets, prevUrl)
    this.setNavLink(this.navNextTargets, nextUrl)

    // Swipe gestures and the hold-marker hand-off carry their own copies.
    for (const el of document.querySelectorAll("[data-controller~='swipe-nav'], [data-controller~='hold-marker']")) {
      el.dataset.swipeNavPrevUrlValue = prevUrl
      el.dataset.swipeNavNextUrlValue = nextUrl
    }
    for (const el of document.querySelectorAll("[data-controller~='problem-data']")) {
      el.dataset.problemDataPrevUrlValue = prevUrl
      el.dataset.problemDataNextUrlValue = nextUrl
    }
  }

  setNavLink(elements, url) {
    for (const el of elements) {
      if (url) {
        el.setAttribute("href", url)
        el.classList.remove("problem-nav-disabled")
      } else {
        el.removeAttribute("href")
        el.classList.add("problem-nav-disabled")
      }
    }
  }

  problemUrl(problemId, params) {
    const query = new URLSearchParams(params).toString()
    return `${this.boardPathValue}/${problemId}${query ? `?${query}` : ""}`
  }

  visit(url) {
    if (window.Turbo) window.Turbo.visit(url)
    else window.location.assign(url)
  }
}
