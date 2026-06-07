import { Controller } from "@hotwired/stimulus"

// When offline, the cached problems index is the unfiltered canonical
// list. This controller reads URL params (filter, sort, min_grade,
// max_grade) and applies them client-side so the existing filter form
// keeps working without a connection.
//
// When online, the server has already filtered the list — we no-op.
export default class extends Controller {
  connect() {
    if (navigator.onLine) return
    this.apply()
  }

  apply() {
    const params = new URLSearchParams(window.location.search)
    const filter = params.get("filter")
    const sort = params.get("sort")
    const minGrade = params.get("min_grade")
    const maxGrade = params.get("max_grade")

    const items = Array.from(this.element.querySelectorAll(".problem-link"))
    if (!items.length) return

    const minIdx = this.gradeIndexFromItems(items, minGrade)
    const maxIdx = this.gradeIndexFromItems(items, maxGrade, items.length)

    for (const item of items) {
      const gradeIndex = parseInt(item.dataset.gradeIndex, 10)
      const sent = item.dataset.sent === "true"
      let visible = true

      if (filter === "sent" && !sent) visible = false
      if (filter === "unsent" && sent) visible = false
      if (minGrade && gradeIndex >= 0 && gradeIndex < minIdx) visible = false
      if (maxGrade && gradeIndex >= 0 && gradeIndex > maxIdx) visible = false

      item.style.display = visible ? "" : "none"
    }

    this.sort(items, sort)
  }

  gradeIndexFromItems(items, grade, fallback = 0) {
    if (!grade) return fallback
    const hit = items.find(i => i.dataset.grade === grade)
    return hit ? parseInt(hit.dataset.gradeIndex, 10) : fallback
  }

  sort(items, mode) {
    if (!mode || mode === "date") {
      items.sort((a, b) => parseInt(b.dataset.createdAt, 10) - parseInt(a.dataset.createdAt, 10))
    } else if (mode === "grade") {
      items.sort((a, b) => parseInt(a.dataset.gradeIndex, 10) - parseInt(b.dataset.gradeIndex, 10))
    } else if (mode === "grade_desc") {
      items.sort((a, b) => parseInt(b.dataset.gradeIndex, 10) - parseInt(a.dataset.gradeIndex, 10))
    }
    const parent = items[0].parentElement
    for (const item of items) parent.appendChild(item)
  }
}
