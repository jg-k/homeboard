import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateState()
  }

  change() {
    this.updateState()
  }

  updateState() {
    if (this.element.files && this.element.files.length > 0) {
      this.element.classList.add("file-input-has-file")
      this.element.classList.remove("file-input-empty")
    } else {
      this.element.classList.remove("file-input-has-file")
      this.element.classList.add("file-input-empty")
    }
  }
}
