import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "label"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.render()
  }

  toggle() {
    this.openValue = !this.openValue
    this.render()
  }

  render() {
    this.contentTarget.classList.toggle("hidden", !this.openValue)
    this.labelTarget.textContent = this.openValue ? "Fewer options" : "More options"
  }
}
