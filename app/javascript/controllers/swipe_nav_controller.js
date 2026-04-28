import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    prevUrl: String,
    nextUrl: String,
    frameId: String,
    threshold: { type: Number, default: 50 }
  }

  connect() {
    this.touchStartX = 0
  }

  touchstart(event) {
    this.touchStartX = event.changedTouches[0].screenX
  }

  touchend(event) {
    const touchEndX = event.changedTouches[0].screenX
    const diff = this.touchStartX - touchEndX

    if (Math.abs(diff) < this.thresholdValue) return

    if (diff > 0 && this.nextUrlValue) {
      this.navigate(this.nextUrlValue)
    } else if (diff < 0 && this.prevUrlValue) {
      this.navigate(this.prevUrlValue)
    }
  }

  navigate(url) {
    if (this.frameIdValue) {
      // Frame navigation - find the frame and load the URL
      const frame = document.getElementById(this.frameIdValue)
      if (frame) {
        frame.src = url
        // Update browser URL
        history.pushState({}, "", url)
      }
    } else {
      // Full page navigation
      Turbo.visit(url)
    }
  }
}
