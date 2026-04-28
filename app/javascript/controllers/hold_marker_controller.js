import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "container", "modeButton", "startHoldsInput", "finishHoldsInput", "handHoldsInput", "footHoldsInput"]
  static values = {
    startHolds: Array,
    finishHolds: Array,
    handHolds: Array,
    footHolds: Array,
    editable: { type: Boolean, default: false }
  }

  connect() {
    this.mode = "start" // start, finish, hand, foot, edit
    this.isDragging = false
    this.dragTarget = null
    this.recentlyTouched = false // prevents click after touch
    this.touchOffsetY = 48 // pixels above finger for touch placement
    this.deleteZone = null

    this.updateModeButtons()

    // Initialize form inputs with current hold values
    this.updateInputs()

    // Wait for image to load before rendering holds
    if (this.hasImageTarget) {
      if (this.imageTarget.complete) {
        this.renderHolds()
      } else {
        this.imageTarget.addEventListener('load', () => {
          this.renderHolds()
        })
      }
      // Add touch event listeners for offset placement
      this.boundHandleTouchStart = this.handleTouchStart.bind(this)
      this.boundHandleTouchMove = this.handleTouchMove.bind(this)
      this.boundHandleTouchEnd = this.handleTouchEnd.bind(this)

      this.containerTarget.addEventListener('touchstart', this.boundHandleTouchStart, { passive: false })
      this.containerTarget.addEventListener('touchmove', this.boundHandleTouchMove, { passive: false })
      this.containerTarget.addEventListener('touchend', this.boundHandleTouchEnd)
    }
  }

  disconnect() {
    // Clean up timers
    if (this.resizeTimeout) {
      clearTimeout(this.resizeTimeout)
    }

    // Clean up touch event listeners
    if (this.hasContainerTarget) {
      this.containerTarget.removeEventListener('touchstart', this.boundHandleTouchStart)
      this.containerTarget.removeEventListener('touchmove', this.boundHandleTouchMove)
      this.containerTarget.removeEventListener('touchend', this.boundHandleTouchEnd)
    }

    this.removeCrosshair()
  }

  // Value change callbacks - re-render when holds change
  startHoldsValueChanged() {
    if (this.hasImageTarget && this.imageTarget.complete) {
      this.renderHolds()
    }
  }

  finishHoldsValueChanged() {
    if (this.hasImageTarget && this.imageTarget.complete) {
      this.renderHolds()
    }
  }

  handHoldsValueChanged() {
    if (this.hasImageTarget && this.imageTarget.complete) {
      this.renderHolds()
    }
  }

  footHoldsValueChanged() {
    if (this.hasImageTarget && this.imageTarget.complete) {
      this.renderHolds()
    }
  }

  // Switch between marking modes
  setMode(event) {
    this.mode = event.currentTarget.dataset.mode
    this.updateModeButtons()
    this.updateCursor()
  }

  // Clear all holds
  clearAll() {
    this.startHoldsValue = []
    this.finishHoldsValue = []
    this.handHoldsValue = []
    this.footHoldsValue = []
    this.renderHolds()
    this.updateInputs()
  }

  // Handle image clicks (mouse only - touch uses offset placement)
  imageClicked(event) {
    if (!this.editableValue) return

    // Skip if this was a touch event (handled separately with offset)
    if (this.recentlyTouched) return

    if (this.mode === "edit" || this.isDragging) return

    // Make sure we're clicking on the image or container, not a hold
    if (event.target.classList.contains('hold-marker')) return

    const rect = this.imageTarget.getBoundingClientRect()
    const x = ((event.clientX - rect.left) / rect.width) * 100
    const y = ((event.clientY - rect.top) / rect.height) * 100

    this.placeHold(x, y)
  }

  // Handle touch start - show crosshair indicator for NEW hold placement
  handleTouchStart(event) {
    if (!this.editableValue) return
    if (this.mode === "edit") return
    if (event.target.classList.contains('hold-marker')) return

    event.preventDefault()
    this.isPlacingNewHold = true
    this.createCrosshair()
    this.updateCrosshairPosition(event.touches[0])
  }

  // Handle touch move - update crosshair position
  handleTouchMove(event) {
    if (!this.crosshairElement) return
    event.preventDefault()
    this.updateCrosshairPosition(event.touches[0])
  }

  // Handle touch end - place hold at crosshair position (only for NEW holds)
  handleTouchEnd(event) {
    // Only place new hold if we started a new hold placement (not dragging existing)
    if (!this.isPlacingNewHold) return
    this.isPlacingNewHold = false

    if (!this.crosshairElement) return

    // Mark as recently touched to prevent click handler
    this.recentlyTouched = true
    setTimeout(() => { this.recentlyTouched = false }, 300)

    const touch = event.changedTouches[0]
    const rect = this.imageTarget.getBoundingClientRect()

    const x = ((touch.clientX - rect.left) / rect.width) * 100
    const offsetY = touch.clientY - this.touchOffsetY
    const y = Math.max(0, Math.min(100, ((offsetY - rect.top) / rect.height) * 100))

    this.removeCrosshair()
    this.placeHold(x, y)
  }

  // Create crosshair indicator
  createCrosshair() {
    this.removeCrosshair()

    const crosshair = document.createElement("div")
    crosshair.className = "touch-crosshair"
    this.crosshairElement = crosshair
    this.containerTarget.appendChild(crosshair)
  }

  // Update crosshair position based on touch
  updateCrosshairPosition(touch) {
    if (!this.crosshairElement) return

    const rect = this.imageTarget.getBoundingClientRect()
    const x = touch.clientX - rect.left
    const y = touch.clientY - this.touchOffsetY - rect.top

    // Clamp to image bounds
    const clampedX = Math.max(0, Math.min(x, rect.width))
    const clampedY = Math.max(0, Math.min(y, rect.height))

    this.crosshairElement.style.left = clampedX + "px"
    this.crosshairElement.style.top = clampedY + "px"
  }

  // Remove crosshair
  removeCrosshair() {
    if (this.crosshairElement) {
      this.crosshairElement.remove()
      this.crosshairElement = null
    }
  }

  // Place a hold at the given coordinates
  placeHold(x, y) {
    const hold = { x: x, y: y, id: this.generateId() }

    if (this.mode === "start") {
      this.startHoldsValue = [...this.startHoldsValue, hold]
    } else if (this.mode === "finish") {
      this.finishHoldsValue = [...this.finishHoldsValue, hold]
    } else if (this.mode === "hand") {
      this.handHoldsValue = [...this.handHoldsValue, hold]
    } else if (this.mode === "foot") {
      this.footHoldsValue = [...this.footHoldsValue, hold]
    }

    this.renderHolds()
    this.updateInputs()
  }

  // Start dragging a hold (works in any mode)
  startDrag(event) {
    if (!this.editableValue) return

    event.preventDefault()
    this.isDragging = true
    this.dragTarget = event.currentTarget
    this.isTouchDrag = !!event.touches

    // Handle both mouse and touch events
    const clientX = event.touches ? event.touches[0].clientX : event.clientX
    const clientY = event.touches ? event.touches[0].clientY : event.clientY

    // Get the target position relative to the container
    const targetRect = this.dragTarget.getBoundingClientRect()

    this.dragOffset = {
      x: clientX - targetRect.left,
      y: clientY - targetRect.top
    }

    // Show crosshair for touch drags
    if (this.isTouchDrag) {
      this.createCrosshair()
    }

    // Show delete zone
    this.showDeleteZone()

    // Store bound functions to properly remove event listeners later
    this.dragHandler = this.drag.bind(this)
    this.stopDragHandler = this.stopDrag.bind(this)

    document.addEventListener("mousemove", this.dragHandler)
    document.addEventListener("mouseup", this.stopDragHandler)
    document.addEventListener("touchmove", this.dragHandler, { passive: false })
    document.addEventListener("touchend", this.stopDragHandler)
  }

  // Handle dragging
  drag(event) {
    if (!this.isDragging || !this.dragTarget) return

    event.preventDefault()

    // Handle both mouse and touch events
    const clientX = event.touches ? event.touches[0].clientX : event.clientX
    const clientY = event.touches ? event.touches[0].clientY : event.clientY

    const imageRect = this.imageTarget.getBoundingClientRect()

    // Calculate hold size for bounds checking (all holds now use spotlight size)
    const spotlightSize = Math.max(18, Math.min(35, imageRect.width * 0.028)) * 2
    const halfSize = spotlightSize / 2

    // Calculate new position relative to image
    // Apply vertical offset for touch to keep hold visible above finger
    let newX = clientX - imageRect.left - this.dragOffset.x
    let newY = clientY - imageRect.top - this.dragOffset.y
    if (this.isTouchDrag) {
      newY -= this.touchOffsetY
    }

    // Keep within image bounds
    newX = Math.max(0, Math.min(newX, imageRect.width - spotlightSize))
    newY = Math.max(0, Math.min(newY, imageRect.height - spotlightSize))

    this.dragTarget.style.left = newX + "px"
    this.dragTarget.style.top = newY + "px"

    // Calculate center position based on hold type
    // For circles: center is in the middle of the element
    // For half-circles: center is at the top-center (the hold point)
    const holdType = this.dragTarget.dataset.holdType
    const isHalfCircle = (holdType === "hand" || holdType === "foot")
    const centerX = newX + halfSize
    const centerY = isHalfCircle ? newY : newY + halfSize

    // Update crosshair position for touch
    if (this.isTouchDrag && this.crosshairElement) {
      this.crosshairElement.style.left = centerX + "px"
      this.crosshairElement.style.top = centerY + "px"
    }

    // Store the current drag position for final update
    this.currentDragPosition = {
      holdId: this.dragTarget.dataset.holdId,
      holdType: holdType,
      x: (centerX / imageRect.width) * 100,
      y: (centerY / imageRect.height) * 100
    }

    // Update spotlight hole position during drag
    this.updateSpotlightHolePosition(this.dragTarget.dataset.holdId, centerX, centerY)

    // Check if over delete zone
    this.updateDeleteZoneHighlight(clientX, clientY)
  }

  // Stop dragging
  stopDrag(event) {
    const clientX = event.changedTouches ? event.changedTouches[0].clientX : event.clientX
    const clientY = event.changedTouches ? event.changedTouches[0].clientY : event.clientY

    // Check if dropped on delete zone
    if (this.isOverDeleteZone(clientX, clientY) && this.currentDragPosition) {
      this.deleteHold(this.currentDragPosition.holdId, this.currentDragPosition.holdType)
    } else if (this.currentDragPosition) {
      this.updateHoldPosition(
        this.currentDragPosition.holdId,
        this.currentDragPosition.x,
        this.currentDragPosition.y
      )
    }

    this.currentDragPosition = null
    this.removeCrosshair()
    this.hideDeleteZone()
    this.isDragging = false
    this.dragTarget = null
    this.isTouchDrag = false
    document.removeEventListener("mousemove", this.dragHandler)
    document.removeEventListener("mouseup", this.stopDragHandler)
    document.removeEventListener("touchmove", this.dragHandler)
    document.removeEventListener("touchend", this.stopDragHandler)
    this.updateInputs()
  }

  // Show delete zone
  showDeleteZone() {
    if (this.deleteZone) return

    const zone = document.createElement("div")
    zone.className = "delete-zone"
    zone.innerHTML = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>'
    this.deleteZone = zone
    this.containerTarget.appendChild(zone)
  }

  // Hide delete zone
  hideDeleteZone() {
    if (this.deleteZone) {
      this.deleteZone.remove()
      this.deleteZone = null
    }
  }

  // Check if coordinates are over delete zone
  isOverDeleteZone(clientX, clientY) {
    if (!this.deleteZone) return false
    const rect = this.deleteZone.getBoundingClientRect()
    return clientX >= rect.left && clientX <= rect.right &&
           clientY >= rect.top && clientY <= rect.bottom
  }

  // Update delete zone highlight
  updateDeleteZoneHighlight(clientX, clientY) {
    if (!this.deleteZone) return
    if (this.isOverDeleteZone(clientX, clientY)) {
      this.deleteZone.classList.add("delete-zone-active")
    } else {
      this.deleteZone.classList.remove("delete-zone-active")
    }
  }

  // Delete a hold by ID and type
  deleteHold(holdId, holdType) {
    if (holdType === "start") {
      this.startHoldsValue = this.startHoldsValue.filter(h => h.id !== holdId)
    } else if (holdType === "finish") {
      this.finishHoldsValue = this.finishHoldsValue.filter(h => h.id !== holdId)
    } else if (holdType === "hand") {
      this.handHoldsValue = this.handHoldsValue.filter(h => h.id !== holdId)
    } else if (holdType === "foot") {
      this.footHoldsValue = this.footHoldsValue.filter(h => h.id !== holdId)
    }
    this.renderHolds()
  }

  // Remove a hold (double-click)
  removeHold(event) {
    if (!this.editableValue) return

    const holdId = event.currentTarget.dataset.holdId
    const holdType = event.currentTarget.dataset.holdType

    if (holdType === "start") {
      this.startHoldsValue = this.startHoldsValue.filter(hold => hold.id !== holdId)
    } else if (holdType === "finish") {
      this.finishHoldsValue = this.finishHoldsValue.filter(hold => hold.id !== holdId)
    } else if (holdType === "hand") {
      this.handHoldsValue = this.handHoldsValue.filter(hold => hold.id !== holdId)
    } else if (holdType === "foot") {
      this.footHoldsValue = this.footHoldsValue.filter(hold => hold.id !== holdId)
    }

    this.renderHolds()
    this.updateInputs()
  }

  // Render all holds on the image
  renderHolds() {
    // Clear existing holds
    this.containerTarget.querySelectorAll(".hold-marker").forEach(el => el.remove())

    const imageRect = this.imageTarget.getBoundingClientRect()

    // Render spotlight overlay (in both view and edit mode)
    this.renderSpotlightOverlay(imageRect)

    // Render start holds (orange circles)
    this.startHoldsValue.forEach(hold => {
      this.createHoldElement(hold, "start", "#ff9500", imageRect, "circle")
    })

    // Render finish holds (green circles)
    this.finishHoldsValue.forEach(hold => {
      this.createHoldElement(hold, "finish", "#16a34a", imageRect, "circle")
    })

    // Render hand holds (red half-circles)
    this.handHoldsValue.forEach(hold => {
      this.createHoldElement(hold, "hand", "#dc2626", imageRect, "half-circle")
    })

    // Render foot holds (max bright yellow half-circles)
    this.footHoldsValue.forEach(hold => {
      this.createHoldElement(hold, "foot", "#ffff00", imageRect, "half-circle")
    })
  }

  // Render the spotlight overlay with holes at hold positions
  renderSpotlightOverlay(imageRect) {
    // Remove existing overlay
    const existingOverlay = this.containerTarget.querySelector(".spotlight-overlay")
    if (existingOverlay) existingOverlay.remove()

    // Collect all holds
    const allHolds = [
      ...this.startHoldsValue,
      ...this.finishHoldsValue,
      ...this.handHoldsValue,
      ...this.footHoldsValue
    ]

    // Don't render overlay if no holds
    if (allHolds.length === 0) return

    // Calculate hole radius based on image width (slightly larger than hold markers)
    const holeRadius = Math.max(18, Math.min(35, imageRect.width * 0.028))

    // Create SVG element
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("class", "spotlight-overlay")
    svg.setAttribute("viewBox", `0 0 ${imageRect.width} ${imageRect.height}`)
    svg.setAttribute("preserveAspectRatio", "none")

    // Create unique mask ID for this instance
    const maskId = `spotlight-mask-${Date.now()}`

    // Create defs and mask
    const defs = document.createElementNS("http://www.w3.org/2000/svg", "defs")
    const mask = document.createElementNS("http://www.w3.org/2000/svg", "mask")
    mask.setAttribute("id", maskId)

    // White rectangle (shows the overlay everywhere)
    const maskRect = document.createElementNS("http://www.w3.org/2000/svg", "rect")
    maskRect.setAttribute("width", "100%")
    maskRect.setAttribute("height", "100%")
    maskRect.setAttribute("fill", "white")
    mask.appendChild(maskRect)

    // Black circles at hold positions (punch holes in the overlay)
    allHolds.forEach(hold => {
      const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle")
      const cx = (hold.x / 100) * imageRect.width
      const cy = (hold.y / 100) * imageRect.height
      circle.setAttribute("cx", cx)
      circle.setAttribute("cy", cy)
      circle.setAttribute("r", holeRadius)
      circle.setAttribute("fill", "black")
      circle.setAttribute("data-hold-id", hold.id)
      circle.classList.add("spotlight-hole")
      mask.appendChild(circle)
    })

    defs.appendChild(mask)
    svg.appendChild(defs)

    // Create the overlay rectangle with the mask applied
    const overlayRect = document.createElementNS("http://www.w3.org/2000/svg", "rect")
    overlayRect.setAttribute("width", "100%")
    overlayRect.setAttribute("height", "100%")
    overlayRect.setAttribute("class", "overlay-fill")
    overlayRect.setAttribute("mask", `url(#${maskId})`)
    svg.appendChild(overlayRect)

    this.containerTarget.appendChild(svg)
  }

  // Update a single spotlight hole position during drag
  updateSpotlightHolePosition(holdId, x, y) {
    const circle = this.containerTarget.querySelector(`.spotlight-hole[data-hold-id="${holdId}"]`)
    if (circle) {
      circle.setAttribute("cx", x)
      circle.setAttribute("cy", y)
    }
  }

  // Create a hold element
  createHoldElement(hold, type, color, imageRect, shape) {
    const holdEl = document.createElement("div")
    holdEl.className = "hold-marker absolute cursor-pointer"
    holdEl.dataset.holdId = hold.id
    holdEl.dataset.holdType = type

    // Calculate hold size to match spotlight hole diameter
    const spotlightSize = Math.max(18, Math.min(35, imageRect.width * 0.028)) * 2

    if (shape === "circle") {
      // Full circles for start/finish holds - sized to match spotlight holes
      const circleBorderWidth = Math.max(3, spotlightSize * 0.12)
      holdEl.style.width = spotlightSize + "px"
      holdEl.style.height = spotlightSize + "px"
      holdEl.style.borderRadius = "50%"
      holdEl.style.border = `${circleBorderWidth}px solid ${color}`
      holdEl.style.backgroundColor = "transparent"
      holdEl.style.left = (hold.x / 100) * imageRect.width - (spotlightSize / 2) + "px"
      holdEl.style.top = (hold.y / 100) * imageRect.height - (spotlightSize / 2) + "px"
    } else if (shape === "half-circle") {
      // Bottom half circles for hand/foot holds - aligned with bottom half of spotlight
      const halfCircleBorderWidth = Math.max(3, spotlightSize * 0.12)
      holdEl.style.width = spotlightSize + "px"
      holdEl.style.height = (spotlightSize / 2) + "px"
      holdEl.style.backgroundColor = "transparent"
      holdEl.style.border = `${halfCircleBorderWidth}px solid ${color}`
      holdEl.style.borderTop = "none"
      holdEl.style.borderRadius = `0 0 ${spotlightSize / 2}px ${spotlightSize / 2}px`
      holdEl.style.left = (hold.x / 100) * imageRect.width - (spotlightSize / 2) + "px"
      holdEl.style.top = (hold.y / 100) * imageRect.height + "px"
    }

    // Add event listeners for mouse and touch
    holdEl.addEventListener("mousedown", this.startDrag.bind(this))
    holdEl.addEventListener("touchstart", this.startDrag.bind(this), { passive: false })
    holdEl.addEventListener("dblclick", this.removeHold.bind(this))

    this.containerTarget.appendChild(holdEl)
  }

  // Update hold position in data
  updateHoldPosition(holdId, x, y) {
    const startIndex = this.startHoldsValue.findIndex(hold => hold.id === holdId)
    if (startIndex !== -1) {
      // Create a new array to trigger Stimulus value change
      const newStartHolds = [...this.startHoldsValue]
      newStartHolds[startIndex] = { ...newStartHolds[startIndex], x: x, y: y }
      this.startHoldsValue = newStartHolds
      return
    }

    const finishIndex = this.finishHoldsValue.findIndex(hold => hold.id === holdId)
    if (finishIndex !== -1) {
      const newFinishHolds = [...this.finishHoldsValue]
      newFinishHolds[finishIndex] = { ...newFinishHolds[finishIndex], x: x, y: y }
      this.finishHoldsValue = newFinishHolds
      return
    }

    const handIndex = this.handHoldsValue.findIndex(hold => hold.id === holdId)
    if (handIndex !== -1) {
      const newHandHolds = [...this.handHoldsValue]
      newHandHolds[handIndex] = { ...newHandHolds[handIndex], x: x, y: y }
      this.handHoldsValue = newHandHolds
      return
    }

    const footIndex = this.footHoldsValue.findIndex(hold => hold.id === holdId)
    if (footIndex !== -1) {
      const newFootHolds = [...this.footHoldsValue]
      newFootHolds[footIndex] = { ...newFootHolds[footIndex], x: x, y: y }
      this.footHoldsValue = newFootHolds
    }
  }

  // Update mode button styles
  updateModeButtons() {
    this.modeButtonTargets.forEach(btn => {
      btn.classList.remove("hold-mode-btn-active")
      btn.classList.add("hold-mode-btn-inactive")

      if (btn.dataset.mode === this.mode) {
        btn.classList.remove("hold-mode-btn-inactive")
        btn.classList.add("hold-mode-btn-active")
      }
    })
  }

  // Update cursor based on mode
  updateCursor() {
    if (this.mode === "edit") {
      this.containerTarget.style.cursor = "default"
    } else {
      this.containerTarget.style.cursor = "crosshair"
    }
  }

  // Update hidden form inputs
  updateInputs() {
    const startHoldsJson = JSON.stringify(this.startHoldsValue)
    const finishHoldsJson = JSON.stringify(this.finishHoldsValue)
    const handHoldsJson = JSON.stringify(this.handHoldsValue)
    const footHoldsJson = JSON.stringify(this.footHoldsValue)

    // Find inputs using targets first, then fall back to selectors
    const startInput = this.hasStartHoldsInputTarget ? this.startHoldsInputTarget : 
                      document.querySelector('[data-hold-marker-target="startHoldsInput"]') || 
                      document.querySelector('input[name*="start_holds"]') ||
                      document.querySelector('#problem_start_holds')
    const finishInput = this.hasFinishHoldsInputTarget ? this.finishHoldsInputTarget :
                       document.querySelector('[data-hold-marker-target="finishHoldsInput"]') || 
                       document.querySelector('input[name*="finish_holds"]') ||
                       document.querySelector('#problem_finish_holds')
    const handInput = this.hasHandHoldsInputTarget ? this.handHoldsInputTarget :
                     document.querySelector('[data-hold-marker-target="handHoldsInput"]') || 
                     document.querySelector('input[name*="hand_holds"]') ||
                     document.querySelector('#problem_hand_holds')
    const footInput = this.hasFootHoldsInputTarget ? this.footHoldsInputTarget :
                     document.querySelector('[data-hold-marker-target="footHoldsInput"]') || 
                     document.querySelector('input[name*="foot_holds"]') ||
                     document.querySelector('#problem_foot_holds')

    if (startInput) startInput.value = startHoldsJson
    if (finishInput) finishInput.value = finishHoldsJson
    if (handInput) handInput.value = handHoldsJson
    if (footInput) footInput.value = footHoldsJson
  }

  // Generate unique ID for holds
  generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substring(2)
  }

  // Handle window resize to reposition holds
  windowResized() {
    // Debounce resize events
    clearTimeout(this.resizeTimeout)
    this.resizeTimeout = setTimeout(() => {
      this.renderHolds()
    }, 100)
  }
}