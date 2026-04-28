import { Controller } from "@hotwired/stimulus"

// Dispatches hold data to the hold-marker controller when turbo frame updates
export default class extends Controller {
  static values = {
    startHolds: Array,
    finishHolds: Array,
    handHolds: Array,
    footHolds: Array,
    imageUrl: String,
    prevUrl: String,
    nextUrl: String,
    frameId: String
  }

  connect() {
    this.updateHoldMarker()
  }

  updateHoldMarker() {
    // Update ALL hold-marker elements (both mobile and desktop)
    const holdMarkerElements = document.querySelectorAll("[data-controller~='hold-marker']")
    if (!holdMarkerElements.length) return

    holdMarkerElements.forEach(holdMarkerElement => {
      const img = holdMarkerElement.querySelector("[data-hold-marker-target='image']")

      // Check if image URL changed (different layout)
      const currentImageUrl = holdMarkerElement.dataset.problemDataCurrentImageUrl
      const imageChanged = this.imageUrlValue && currentImageUrl !== this.imageUrlValue

      if (imageChanged && img) {
        // Image is changing - update src and wait for load before updating holds
        img.src = this.imageUrlValue
        holdMarkerElement.dataset.problemDataCurrentImageUrl = this.imageUrlValue

        img.addEventListener("load", () => {
          this.updateHoldData(holdMarkerElement)
        }, { once: true })
      } else {
        // Same image - just update hold data
        this.updateHoldData(holdMarkerElement)
      }
    })
  }

  updateHoldData(holdMarkerElement) {
    // Update hold data attributes - Stimulus will detect the changes
    holdMarkerElement.dataset.holdMarkerStartHoldsValue = JSON.stringify(this.startHoldsValue)
    holdMarkerElement.dataset.holdMarkerFinishHoldsValue = JSON.stringify(this.finishHoldsValue)
    holdMarkerElement.dataset.holdMarkerHandHoldsValue = JSON.stringify(this.handHoldsValue)
    holdMarkerElement.dataset.holdMarkerFootHoldsValue = JSON.stringify(this.footHoldsValue)

    // Update swipe-nav URLs for the image container
    holdMarkerElement.dataset.swipeNavPrevUrlValue = this.prevUrlValue || ""
    holdMarkerElement.dataset.swipeNavNextUrlValue = this.nextUrlValue || ""
    if (this.frameIdValue) {
      holdMarkerElement.dataset.swipeNavFrameIdValue = this.frameIdValue
    }
  }
}
