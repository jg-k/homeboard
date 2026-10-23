import { Controller } from "@hotwired/stimulus"

const GET_READY_SECONDS = 5
const TICK_MS = 100

// Counts down a hang protocol: a short get-ready, then `reps` hangs of `work`
// seconds with `rest` seconds between them. Beeps on the last three seconds
// of each phase and when a phase starts, and keeps the screen awake while it
// runs. Time comes from the clock, not from counting ticks, so a throttled
// tab doesn't drift.
export default class extends Controller {
  static targets = ["display", "phase", "clock", "count", "toggle", "work", "rest", "reps", "submit"]

  connect() {
    this.reset()
  }

  disconnect() {
    this.pause()
    this.audio?.close()
  }

  toggle() {
    this.running ? this.pause() : this.start()
  }

  start() {
    if (this.finished) this.reset()
    if (!this.steps) this.prepare()

    this.audio ||= new AudioContext()
    this.running = true
    this.endsAt = Date.now() + this.remainingMs
    this.interval = setInterval(() => this.tick(), TICK_MS)
    this.toggleTarget.textContent = "Pause"
    this.keepAwake()
    this.render()
  }

  pause() {
    if (!this.running) return

    this.running = false
    clearInterval(this.interval)
    this.remainingMs = this.endsAt - Date.now()
    this.toggleTarget.textContent = "Resume"
    this.releaseWakeLock()
  }

  reset() {
    this.pause()
    this.steps = null
    this.finished = false
    this.toggleTarget.textContent = "Start"
    this.show("idle", "Ready", this.seconds(this.workTarget), " ")
  }

  // private

  prepare() {
    const work = this.seconds(this.workTarget)
    const rest = this.seconds(this.restTarget)
    const reps = Math.max(1, Math.round(this.seconds(this.repsTarget)))

    this.steps = [ { phase: "ready", label: "Get ready", seconds: GET_READY_SECONDS } ]
    for (let rep = 1; rep <= reps; rep++) {
      this.steps.push({ phase: "hang", label: "Hang", seconds: work, rep, reps })
      if (rep < reps && rest > 0) this.steps.push({ phase: "rest", label: "Rest", seconds: rest, rep, reps })
    }
    this.index = 0
    this.remainingMs = this.steps[0].seconds * 1000
    this.lastSecond = null
  }

  tick() {
    this.remainingMs = this.endsAt - Date.now()

    while (this.remainingMs <= 0) {
      this.index++
      if (this.index >= this.steps.length) return this.finish()

      this.endsAt += this.step.seconds * 1000
      this.remainingMs = this.endsAt - Date.now()
      this.beep(this.step.phase === "hang" ? 880 : 440, 400)
      navigator.vibrate?.(200)
    }

    this.render()
  }

  render() {
    const second = Math.ceil(this.remainingMs / 1000)
    if (this.running && second !== this.lastSecond && second <= 3 && second > 0) this.beep(660, 120)
    this.lastSecond = second

    const count = this.step.rep ? `Rep ${this.step.rep} of ${this.step.reps}` : " "
    this.show(this.step.phase, this.step.label, second, count)
  }

  finish() {
    this.pause()
    this.finished = true
    this.toggleTarget.textContent = "Again"
    this.show("done", "Done", "✓", "Log the set below")
    this.beep(880, 800)
    navigator.vibrate?.([ 200, 100, 200 ])
    this.submitTarget.focus()
  }

  show(phase, label, clock, count) {
    this.displayTarget.dataset.phase = phase
    this.phaseTarget.textContent = label
    this.clockTarget.textContent = clock
    this.countTarget.textContent = count
  }

  get step() {
    return this.steps[this.index]
  }

  seconds(input) {
    return Math.max(0, parseFloat(input.value) || 0)
  }

  beep(frequency, durationMs) {
    if (!this.audio) return

    const oscillator = this.audio.createOscillator()
    const gain = this.audio.createGain()
    oscillator.frequency.value = frequency
    gain.gain.value = 0.2
    oscillator.connect(gain).connect(this.audio.destination)
    oscillator.start()
    oscillator.stop(this.audio.currentTime + durationMs / 1000)
  }

  async keepAwake() {
    try {
      this.wakeLock = await navigator.wakeLock?.request("screen")
      if (!this.running) this.releaseWakeLock()
    } catch {
      // Not supported, or the page is hidden: the timer still runs.
    }
  }

  releaseWakeLock() {
    this.wakeLock?.release()
    this.wakeLock = null
  }
}
