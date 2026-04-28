import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "unit", "addedWeightGroup", "reps"]

  connect() {
    this.update()
  }

  update() {
    const selected = this.selectTarget.selectedOptions[0]
    const unit = selected?.dataset?.unit || ""
    this.unitTarget.textContent = unit ? `(${unit})` : ""

    if (this.hasAddedWeightGroupTarget) {
      const addedWeight = selected?.dataset?.addedWeight === "true"
      this.addedWeightGroupTarget.style.display = addedWeight ? "" : "none"
    }

    if (this.hasRepsTarget && !this.repsTarget.value) {
      const reps = selected?.dataset?.reps
      this.repsTarget.placeholder = reps ? `Default: ${reps}` : "Optional"
    }
  }
}
