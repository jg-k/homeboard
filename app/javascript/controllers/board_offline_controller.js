import { Controller } from "@hotwired/stimulus"

// Pins or unpins a board for offline use.
// Pinning fetches the offline manifest and tells the service worker
// to cache the board page, every problem page, and every layout image.
export default class extends Controller {
  static values = { boardId: Number, manifestPath: String }
  static targets = ["button", "status"]

  connect() {
    this.render()
  }

  async toggle(event) {
    event.preventDefault()
    if (this.isPinned()) {
      await this.unpin()
    } else {
      await this.pin()
    }
    this.render()
  }

  async pin() {
    if (!("serviceWorker" in navigator) || !navigator.serviceWorker.controller) {
      this.setStatus("Service worker not ready — reload the page and try again.")
      return
    }
    this.setStatus("Downloading…")
    let manifest
    try {
      manifest = await this.fetchManifest()
    } catch (e) {
      this.setStatus("Couldn't reach the server. Try again online.")
      return
    }
    const urls = this.urlsFromManifest(manifest)
    this.listenForProgress(urls.length)
    navigator.serviceWorker.controller.postMessage({ type: "PIN", payload: { urls } })

    const pinned = this.readPinnedSet()
    pinned.add(this.boardIdValue)
    this.writePinnedSet(pinned)
    localStorage.setItem(this.snapshotKey(), JSON.stringify(manifest))
  }

  async unpin() {
    const snapshot = this.readSnapshot()
    if (snapshot && navigator.serviceWorker.controller) {
      navigator.serviceWorker.controller.postMessage({
        type: "UNPIN",
        payload: { urls: this.urlsFromManifest(snapshot) }
      })
    }
    const pinned = this.readPinnedSet()
    pinned.delete(this.boardIdValue)
    this.writePinnedSet(pinned)
    localStorage.removeItem(this.snapshotKey())
    this.setStatus("Removed from offline.")
  }

  async fetchManifest() {
    const res = await fetch(this.manifestPathValue, {
      credentials: "same-origin",
      headers: { Accept: "application/json" }
    })
    if (!res.ok) throw new Error("manifest fetch failed")
    return await res.json()
  }

  urlsFromManifest(manifest) {
    const origin = window.location.origin
    const urls = [
      // Common entry points so offline navigation from /, /problems, /boards works.
      origin + "/",
      origin + "/problems",
      origin + "/boards",
      manifest.board_url,
      manifest.board_url + "/problems"
    ]
    for (const p of manifest.problems || []) {
      urls.push(p.url)
      urls.push(`${p.url}/edit`)
    }
    for (const l of manifest.layouts || []) {
      if (l.image_url) urls.push(l.image_url)
    }
    // Default "new problem" form (uses the active layout).
    urls.push(`${manifest.board_url}/problems/new`)
    for (const u of this.assetUrlsFromDocument()) urls.push(u)
    return [...new Set(urls)]
  }

  // Walks the current document for stylesheets, the importmap module URLs,
  // and PWA icons. Cached up-front so the offline shell renders correctly
  // without needing the user to warm the asset cache by browsing.
  assetUrlsFromDocument() {
    const urls = []
    const absolute = (href) => new URL(href, document.baseURI).toString()

    document.querySelectorAll('link[rel="stylesheet"][href]')
      .forEach(l => urls.push(absolute(l.getAttribute("href"))))
    document.querySelectorAll('link[rel="icon"][href], link[rel="apple-touch-icon"][href]')
      .forEach(l => urls.push(absolute(l.getAttribute("href"))))
    document.querySelectorAll('link[rel="manifest"][href]')
      .forEach(l => urls.push(absolute(l.getAttribute("href"))))
    document.querySelectorAll('script[src]')
      .forEach(s => urls.push(absolute(s.getAttribute("src"))))

    const importmap = document.querySelector('script[type="importmap"]')
    if (importmap) {
      try {
        const map = JSON.parse(importmap.textContent)
        for (const ref of Object.values(map.imports || {})) {
          if (typeof ref !== "string") continue
          if (ref.startsWith("/") || ref.startsWith("http://") || ref.startsWith("https://")) {
            urls.push(absolute(ref))
          }
        }
      } catch (_) { /* ignore parse error */ }
    }
    return urls
  }

  listenForProgress(total) {
    const handler = (event) => {
      const { type, done } = event.data || {}
      if (type === "PIN_PROGRESS") {
        this.setStatus(`Downloading… ${done}/${total}`)
      } else if (type === "PIN_DONE") {
        this.setStatus("Available offline.")
        navigator.serviceWorker.removeEventListener("message", handler)
      }
    }
    navigator.serviceWorker.addEventListener("message", handler)
  }

  isPinned() {
    return this.readPinnedSet().has(this.boardIdValue)
  }

  readPinnedSet() {
    try {
      return new Set(JSON.parse(localStorage.getItem("homeboard:pinned") || "[]"))
    } catch { return new Set() }
  }

  writePinnedSet(set) {
    localStorage.setItem("homeboard:pinned", JSON.stringify([...set]))
  }

  snapshotKey() {
    return `homeboard:manifest:${this.boardIdValue}`
  }

  readSnapshot() {
    try {
      return JSON.parse(localStorage.getItem(this.snapshotKey()) || "null")
    } catch { return null }
  }

  setStatus(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }

  render() {
    if (!this.hasButtonTarget) return
    const pinned = this.isPinned()
    this.buttonTarget.textContent = pinned ? "Remove offline copy" : "Make available offline"
    this.buttonTarget.classList.toggle("btn-primary", !pinned)
    this.buttonTarget.classList.toggle("btn-outline", pinned)
    if (!this.hasStatusTarget) return
    if (pinned) this.statusTarget.textContent = "Available offline."
    else this.statusTarget.textContent = ""
  }
}
