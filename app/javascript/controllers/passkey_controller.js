import { Controller } from "@hotwired/stimulus"

// Drives both WebAuthn ceremonies — `register` in settings, `authenticate` on
// the sign-in page. `navigator.credentials` has no non-JS equivalent, so this
// is the one part of the passkey flow that has to be scripted: fetch the
// options, hand them to the authenticator, then post the signed result back
// through a normal form submit so Turbo still handles the redirect and flash.
export default class extends Controller {
  static targets = ["credential", "submit", "error", "name"]
  static values = { optionsUrl: String }

  async register(event) {
    event.preventDefault()
    this.clearError()

    if (!window.PublicKeyCredential) {
      this.showError("This browser does not support passkeys.")
      return
    }

    this.submitTarget.disabled = true

    try {
      const options = await this.fetchOptions()
      const credential = await navigator.credentials.create({ publicKey: options })
      this.credentialTarget.value = JSON.stringify(this.serialize(credential))
      this.element.requestSubmit()
    } catch (error) {
      this.submitTarget.disabled = false
      // The user dismissing the system prompt is a normal outcome, not an error.
      if (error.name === "NotAllowedError") return
      this.showError(
        error.userMessage ||
        (error.name === "InvalidStateError"
          ? "This device already has a passkey for your account."
          : "Could not create a passkey. Please try again.")
      )
    }
  }

  async authenticate(event) {
    event.preventDefault()
    this.clearError()

    if (!window.PublicKeyCredential) {
      this.showError("This browser does not support passkeys.")
      return
    }

    this.submitTarget.disabled = true

    try {
      const options = await this.fetchOptions()
      const credential = await navigator.credentials.get({ publicKey: options })
      this.credentialTarget.value = JSON.stringify(this.serializeAssertion(credential))
      this.element.requestSubmit()
    } catch (error) {
      this.submitTarget.disabled = false
      if (error.name === "NotAllowedError") return
      this.showError(error.userMessage || "Could not use a passkey. Please try again.")
    }
  }

  async fetchOptions() {
    // Sign-up sends the chosen display name along so the server can reject a
    // taken one before the user is asked for a fingerprint.
    const url = new URL(this.optionsUrlValue, window.location.origin)
    if (this.hasNameTarget) url.searchParams.set("display_name", this.nameTarget.value)

    const response = await fetch(url, {
      credentials: "same-origin",
      headers: { Accept: "application/json" }
    })
    if (!response.ok) throw await this.optionsError(response)

    const options = await response.json()
    options.challenge = this.decode(options.challenge)
    if (options.user) options.user.id = this.decode(options.user.id)
    for (const key of ["excludeCredentials", "allowCredentials"]) {
      if (!options[key]) continue
      options[key] = options[key].map((credential) => ({ ...credential, id: this.decode(credential.id) }))
    }
    return options
  }

  serialize(credential) {
    return {
      type: credential.type,
      id: credential.id,
      rawId: this.encode(credential.rawId),
      authenticatorAttachment: credential.authenticatorAttachment,
      clientExtensionResults: credential.getClientExtensionResults(),
      response: {
        attestationObject: this.encode(credential.response.attestationObject),
        clientDataJSON: this.encode(credential.response.clientDataJSON),
        transports: credential.response.getTransports ? credential.response.getTransports() : []
      }
    }
  }

  async optionsError(response) {
    const error = new Error(`options request failed: ${response.status}`)
    error.userMessage = await response.json().then((body) => body.error).catch(() => null)
    return error
  }

  serializeAssertion(credential) {
    return {
      type: credential.type,
      id: credential.id,
      rawId: this.encode(credential.rawId),
      authenticatorAttachment: credential.authenticatorAttachment,
      clientExtensionResults: credential.getClientExtensionResults(),
      response: {
        authenticatorData: this.encode(credential.response.authenticatorData),
        clientDataJSON: this.encode(credential.response.clientDataJSON),
        signature: this.encode(credential.response.signature),
        userHandle: credential.response.userHandle ? this.encode(credential.response.userHandle) : null
      }
    }
  }

  // WebAuthn speaks ArrayBuffers; JSON speaks base64url. These two bridge it.
  decode(value) {
    const base64 = value.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(value.length / 4) * 4, "=")
    const binary = atob(base64)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
    return bytes.buffer
  }

  encode(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ""
    for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i])
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
  }

  clearError() {
    this.errorTarget.textContent = ""
    this.errorTarget.hidden = true
  }
}
