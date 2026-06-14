import { Controller } from "@hotwired/stimulus"

// Wraps the board-climb log form. We always intercept the submit and POST
// it ourselves. If the fetch fails with a network error, we queue the
// payload in localStorage; the `sync` controller replays it on reconnect.
//
// We do not trust navigator.onLine — Chrome DevTools' offline throttling
// frequently leaves it true. The fetch outcome is the only reliable signal.
export default class extends Controller {
  static targets = ["status"]

  async submit(event) {
    event.preventDefault()
    const form = event.target
    const submitButton = form.querySelector('input[type="submit"], button[type="submit"]')
    if (submitButton) submitButton.disabled = true

    try {
      const res = await fetch(form.action, {
        method: (form.method || "POST").toUpperCase(),
        body: new FormData(form),
        credentials: "same-origin",
        headers: { Accept: "text/html" },
        redirect: "follow"
      })
      if (!res.ok && res.status !== 302) throw new Error(`status ${res.status}`)
      this.navigateTo(res.url || window.location.href)
    } catch (_) {
      this.queueSubmission(form)
      this.notifyQueued()
      form.reset()
      if (submitButton) submitButton.disabled = false
    }
  }

  queueSubmission(form) {
    const formData = []
    new FormData(form).forEach((value, key) => {
      if (value instanceof File) return
      formData.push([key, String(value)])
    })
    const queue = this.readQueue()
    queue.push({
      id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      url: form.action,
      formData,
      queuedAt: new Date().toISOString()
    })
    this.writeQueue(queue)
  }

  navigateTo(url) {
    if (window.Turbo) window.Turbo.visit(url)
    else window.location.href = url
  }

  notifyQueued() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Logged offline — will sync when you're back online."
      this.statusTarget.classList.add("text-success")
    } else {
      const el = document.createElement("div")
      el.className = "alert alert-success"
      el.textContent = "Logged offline — will sync when you're back online."
      document.body.prepend(el)
      setTimeout(() => el.remove(), 4000)
    }
  }

  readQueue() {
    try { return JSON.parse(localStorage.getItem("homeboard:queue") || "[]") } catch { return [] }
  }

  writeQueue(arr) {
    localStorage.setItem("homeboard:queue", JSON.stringify(arr))
  }
}
