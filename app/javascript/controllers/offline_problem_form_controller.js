import { Controller } from "@hotwired/stimulus"

// Wraps the new/edit-problem form. We always intercept the submit and
// POST it ourselves; on network failure we queue the payload to be
// replayed by the `sync` controller when the network is back.
//
// navigator.onLine is unreliable (Chrome DevTools' offline throttle does
// not flip it), so we use the fetch outcome as the source of truth.
export default class extends Controller {
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
      this.flash("Saved offline — your new problem will sync when you're back online.")
      if (form.dataset.offlineProblemFormReturnTo) {
        this.navigateTo(form.dataset.offlineProblemFormReturnTo)
      } else {
        form.reset()
        if (submitButton) submitButton.disabled = false
      }
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

  flash(text) {
    const el = document.createElement("div")
    el.className = "alert alert-success"
    el.textContent = text
    document.body.prepend(el)
    setTimeout(() => el.remove(), 4000)
  }

  readQueue() {
    try { return JSON.parse(localStorage.getItem("homeboard:queue") || "[]") } catch { return [] }
  }

  writeQueue(arr) {
    localStorage.setItem("homeboard:queue", JSON.stringify(arr))
  }
}
