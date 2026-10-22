import { Controller } from "@hotwired/stimulus"

// A tab row that is wider than the screen scrolls sideways. Bring the active
// tab into view on load, so the tab you are on is never hidden off the edge.
export default class extends Controller {
  connect() {
    const active = this.element.querySelector("[aria-current]")
    if (!active) return

    const row = this.element
    const left = active.offsetLeft - row.offsetLeft
    if (left + active.offsetWidth > row.scrollLeft + row.clientWidth || left < row.scrollLeft) {
      row.scrollLeft = left - (row.clientWidth - active.offsetWidth) / 2
    }
  }
}
