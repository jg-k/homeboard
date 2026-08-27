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

    this.restoreLayoutNarrowing(params)
    this.restoreCancelLink(params)

    this.boundSubmit = (event) => this.submit(event)
    this.element.addEventListener("submit", this.boundSubmit)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.boundSubmit)
  }

  // Turbo navigates a form submission to the *response's* URL, and the
  // service worker serves pinned pages under a query-stripped cache key —
  // so on a pinned board the filter params would vanish from the address
  // bar before offline-filter ever saw them. Visit the submission URL
  // directly instead; a visit keeps its own URL regardless of what the
  // cache answers with.
  submit(event) {
    event.preventDefault()
    const url = new URL(this.element.action, window.location.origin)
    for (const [name, value] of new FormData(this.element)) {
      if (value) url.searchParams.set(name, value)
    }
    const destination = url.pathname + url.search
    if (window.Turbo) window.Turbo.visit(destination)
    else window.location.assign(destination)
  }

  // The cached form was rendered without a query string, so the hidden
  // board_layout_id field the live render would carry is missing entirely.
  restoreLayoutNarrowing(params) {
    const layoutId = params.get("board_layout_id")
    if (!layoutId || this.element.elements.board_layout_id) return

    const input = document.createElement("input")
    input.type = "hidden"
    input.name = "board_layout_id"
    input.value = layoutId
    this.element.appendChild(input)
  }

  // Cancel should return to the list with the filters you arrived with,
  // which on a cached render the server didn't know about.
  restoreCancelLink(params) {
    if ([...params.keys()].length === 0) return
    const cancel = this.element.querySelector("a[href]")
    if (!cancel) return
    const url = new URL(cancel.getAttribute("href"), window.location.origin)
    cancel.setAttribute("href", url.pathname + "?" + params.toString())
  }

  select(name, value) {
    const field = this.element.elements[name]
    if (!field) return

    // A radio group comes back as a RadioNodeList; setting `value` picks the
    // matching button, and "" clears the group for the "Show all" default.
    field.value = value
  }
}
