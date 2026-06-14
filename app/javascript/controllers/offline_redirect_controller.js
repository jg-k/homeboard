import { Controller } from "@hotwired/stimulus"

// On the offline fallback page, rewrites the "go back" link to point at
// a pinned board's problems page (the most useful destination available
// offline) instead of the bare /boards index.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    const url = this.pinnedBoardProblemsUrl()
    if (!url) return
    this.linkTarget.href = url
    this.linkTarget.textContent = "Go to board problems"
  }

  pinnedBoardProblemsUrl() {
    let pinned
    try {
      pinned = JSON.parse(localStorage.getItem("homeboard:pinned") || "[]")
    } catch { return null }
    if (!pinned.length) return null
    const boardId = pinned[0]
    let manifest
    try {
      manifest = JSON.parse(localStorage.getItem(`homeboard:manifest:${boardId}`) || "null")
    } catch { return null }
    if (!manifest || !manifest.board_url) return null
    return `${manifest.board_url}/problems`
  }
}
