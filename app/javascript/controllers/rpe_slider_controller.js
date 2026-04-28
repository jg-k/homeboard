import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider", "display", "hidden", "clear"]

  connect() {
    if (!this.hiddenTarget.value) {
      this.sliderTarget.classList.add("form-range-unset")
    }
  }

  update() {
    const value = this.sliderTarget.value
    this.hiddenTarget.value = value
    this.displayTarget.textContent = value
    this.clearTarget.classList.remove("hidden")
    this.sliderTarget.classList.remove("form-range-unset")
  }

  clear() {
    this.hiddenTarget.value = ""
    this.displayTarget.textContent = "–"
    this.clearTarget.classList.add("hidden")
    this.sliderTarget.classList.add("form-range-unset")
  }
}
