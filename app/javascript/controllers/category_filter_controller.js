import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]
  static values = { url: String }

  filter() {
    const category = this.selectTarget.value
    const url = new URL(this.urlValue, window.location.origin)
    if (category) {
      url.searchParams.set("category", category)
    }
    Turbo.visit(url.toString())
  }
}
