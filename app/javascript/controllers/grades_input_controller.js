import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "newGrade"]

  connect() {
    this.updateHiddenInput()
    this.enableDragAndDrop()
  }

  addGrade(event) {
    event.preventDefault()
    this.insertGrade(false)
  }

  prependGrade(event) {
    event.preventDefault()
    this.insertGrade(true)
  }

  insertGrade(prepend) {
    const value = this.newGradeTarget.value.trim()
    if (value === "") return

    const gradeSpan = this.createGradeSpan(value)

    if (prepend) {
      this.containerTarget.insertBefore(gradeSpan, this.containerTarget.firstChild)
    } else {
      this.containerTarget.appendChild(gradeSpan)
    }

    this.newGradeTarget.value = ""
    this.newGradeTarget.focus()
    this.updateHiddenInput()
  }

  createGradeSpan(value) {
    const gradeSpan = document.createElement("span")
    gradeSpan.className = "bg-blue-100 text-blue-800 px-3 py-1 rounded text-sm flex items-center gap-1 cursor-move"
    gradeSpan.draggable = true
    gradeSpan.dataset.grade = value
    gradeSpan.innerHTML = `${this.escapeHtml(value)} <button type="button" data-action="click->grades-input#removeGrade" class="text-blue-600 hover:text-blue-800 ml-1">&times;</button>`
    return gradeSpan
  }

  removeGrade(event) {
    event.preventDefault()
    const gradeSpan = event.target.closest("[data-grade]")
    if (gradeSpan) {
      gradeSpan.remove()
      this.updateHiddenInput()
    }
  }

  enableDragAndDrop() {
    this.containerTarget.addEventListener("dragstart", (e) => {
      if (e.target.dataset.grade) {
        e.target.classList.add("opacity-50")
        e.dataTransfer.effectAllowed = "move"
        this.draggedElement = e.target
      }
    })

    this.containerTarget.addEventListener("dragend", (e) => {
      if (e.target.dataset.grade) {
        e.target.classList.remove("opacity-50")
        this.draggedElement = null
      }
    })

    this.containerTarget.addEventListener("dragover", (e) => {
      e.preventDefault()
      const target = e.target.closest("[data-grade]")
      if (target && target !== this.draggedElement) {
        const rect = target.getBoundingClientRect()
        const midpoint = rect.left + rect.width / 2
        if (e.clientX < midpoint) {
          target.parentNode.insertBefore(this.draggedElement, target)
        } else {
          target.parentNode.insertBefore(this.draggedElement, target.nextSibling)
        }
      }
    })

    this.containerTarget.addEventListener("drop", (e) => {
      e.preventDefault()
      this.updateHiddenInput()
    })
  }

  updateHiddenInput() {
    const grades = Array.from(this.containerTarget.querySelectorAll("[data-grade]"))
      .map(el => el.dataset.grade)
    this.inputTarget.value = JSON.stringify(grades)
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
