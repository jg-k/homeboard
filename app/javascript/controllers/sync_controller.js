import { Controller } from "@hotwired/stimulus"

// Turbo visits are fetches, not navigations, so the browser never checks for a
// new service worker on its own. An installed PWA can stay open for days,
// which is long enough to miss several deploys.
const UPDATE_CHECK_INTERVAL = 15 * 60 * 1000

// Mounted on <body>. On every Turbo visit (and online events) it:
//   1. Asks the service worker to pick up any new deploy.
//   2. Refreshes every pinned board's offline cache by diffing the
//      current manifest against the stored snapshot.
//   3. Replays any queued board-climb POSTs that were made offline.
export default class extends Controller {
  connect() {
    this.boundRun = () => this.run()
    document.addEventListener("turbo:load", this.boundRun)
    window.addEventListener("online", this.boundRun)
    this.run()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.boundRun)
    window.removeEventListener("online", this.boundRun)
  }

  async run() {
    if (!navigator.onLine) return
    await this.checkForNewBuild()
    await this.replayQueue()
    await this.refreshPinnedBoards()
  }

  // ---- deploy pickup ----

  // Two nudges, because they cover different gaps. The update() call makes the
  // browser re-fetch the service worker script so a new deploy gets installed
  // at all; the SYNC message makes the *installed* worker retry a cache warm
  // that failed earlier (it went offline halfway), which activate can't do
  // twice. Both no-op when everything is already current.
  async checkForNewBuild() {
    if (!("serviceWorker" in navigator)) return

    if (navigator.serviceWorker.controller) {
      navigator.serviceWorker.controller.postMessage({ type: "SYNC" })
    }

    const now = Date.now()
    if (this.lastUpdateCheck && now - this.lastUpdateCheck < UPDATE_CHECK_INTERVAL) return
    this.lastUpdateCheck = now

    try {
      const registration = await navigator.serviceWorker.getRegistration()
      if (registration) await registration.update()
    } catch (_) { /* update checks are best-effort */ }
  }

  // ---- pinned-board refresh ----

  async refreshPinnedBoards() {
    if (!("serviceWorker" in navigator) || !navigator.serviceWorker.controller) return
    const pinned = this.readPinnedSet()
    for (const boardId of pinned) {
      try { await this.refreshBoard(boardId) } catch (_) { /* skip */ }
    }
  }

  async refreshBoard(boardId) {
    const res = await fetch(`/boards/${boardId}/offline_manifest.json`, {
      credentials: "same-origin",
      headers: { Accept: "application/json" }
    })
    if (!res.ok) return
    const fresh = await res.json()
    const key = `homeboard:manifest:${boardId}`
    const prev = JSON.parse(localStorage.getItem(key) || "null")
    const diff = this.diffManifests(prev, fresh)
    if (diff.add.length || diff.update.length || diff.remove.length) {
      navigator.serviceWorker.controller.postMessage({ type: "REFRESH", payload: diff })
    }
    localStorage.setItem(key, JSON.stringify(fresh))
  }

  diffManifests(prev, fresh) {
    const add = []
    const update = []
    const remove = []
    if (!prev) {
      // First refresh after pin — nothing was cached besides what pin did.
      return { add, update, remove }
    }

    const prevProblems = new Map((prev.problems || []).map(p => [p.id, p]))
    const freshProblems = new Map((fresh.problems || []).map(p => [p.id, p]))

    for (const [id, p] of freshProblems) {
      const old = prevProblems.get(id)
      if (!old) {
        add.push(p.url)
        add.push(`${p.url}/edit`)
      } else if (old.updated_at !== p.updated_at) {
        update.push(p.url)
        update.push(`${p.url}/edit`)
      }
    }
    for (const [id, p] of prevProblems) {
      if (!freshProblems.has(id)) {
        remove.push(p.url)
        remove.push(`${p.url}/edit`)
      }
    }

    const prevLayouts = new Map((prev.layouts || []).map(l => [l.id, l]))
    for (const l of fresh.layouts || []) {
      if (!l.image_url) continue
      const old = prevLayouts.get(l.id)
      if (!old || !old.image_url) add.push(l.image_url)
      else if (old.image_etag !== l.image_etag) {
        if (old.image_url !== l.image_url) remove.push(old.image_url)
        update.push(l.image_url)
      }
    }
    for (const l of prev.layouts || []) {
      if (l.image_url && !(fresh.layouts || []).some(x => x.id === l.id)) {
        remove.push(l.image_url)
      }
    }

    // If anything changed, also refresh the canonical problems index so
    // the cached list reflects new/removed problems.
    if (add.length || update.length || remove.length) {
      update.push(fresh.board_url + "/problems")
    }

    return { add, update, remove }
  }

  // ---- offline climb queue replay ----

  async replayQueue() {
    const queue = this.readQueue()
    if (!queue.length) return
    const token = this.csrfToken()
    if (!token) return
    const remaining = []
    for (const item of queue) {
      try {
        const body = new URLSearchParams(item.formData)
        const res = await fetch(item.url, {
          method: "POST",
          credentials: "same-origin",
          headers: {
            "X-CSRF-Token": token,
            "Accept": "text/html",
            "Content-Type": "application/x-www-form-urlencoded"
          },
          body
        })
        if (!res.ok && res.status !== 302) remaining.push(item)
      } catch (_) {
        remaining.push(item)
      }
    }
    this.writeQueue(remaining)
    if (remaining.length < queue.length) {
      this.flash(`Synced ${queue.length - remaining.length} offline climb${queue.length - remaining.length > 1 ? "s" : ""}.`)
    }
  }

  // ---- helpers ----

  csrfToken() {
    const el = document.querySelector('meta[name="csrf-token"]')
    return el ? el.content : null
  }

  readPinnedSet() {
    try {
      return new Set(JSON.parse(localStorage.getItem("homeboard:pinned") || "[]"))
    } catch { return new Set() }
  }

  readQueue() {
    try { return JSON.parse(localStorage.getItem("homeboard:queue") || "[]") } catch { return [] }
  }

  writeQueue(arr) {
    localStorage.setItem("homeboard:queue", JSON.stringify(arr))
  }

  flash(text) {
    const el = document.createElement("div")
    el.className = "alert alert-success"
    el.textContent = text
    document.body.prepend(el)
    setTimeout(() => el.remove(), 4000)
  }
}
