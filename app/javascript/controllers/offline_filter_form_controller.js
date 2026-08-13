import { Controller } from "@hotwired/stimulus"

// The filter form is pinned without a query string, so offline it always
// comes back from cache with its fields at their defaults — reopening the
// form would silently reset a filter the user had applied. Restore the
// selections from the URL whenever they disagree with what the server
// rendered. Online the two match and this does nothing.
export default class extends Controller {
  static values = { applied: Object }

  connect() {
    const params = new URLSearchParams(window.location.search)
    const applied = this.appliedValue || {}

    for (const name of ["min_grade", "max_grade", "sort", "filter"]) {
      const wanted = params.get(name) || ""
      if (wanted === (applied[name] || "")) continue
      this.select(name, wanted)
    }
  }

  select(name, value) {
    const field = this.element.elements[name]
    if (!field) return

    // A radio group comes back as a RadioNodeList; setting `value` picks the
    // matching button, and "" clears the group for the "Show all" default.
    field.value = value
  }
}
