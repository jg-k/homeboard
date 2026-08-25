class Settings::PasskeysSection < ApplicationComponent
  def initialize(passkeys:)
    @passkeys = passkeys
  end

  def view_template
    render SettingsSection.new(title: "Passkeys") do
      @passkeys.each { |passkey| passkey_row(passkey) }
      add_row
    end
  end

  private

  def passkey_row(passkey)
    div(class: "settings-row") do
      div(class: "settings-label") do
        span(class: "font-medium flex items-center gap-2") do
          icon(:key, size: :sm)
          plain passkey.nickname
          storage_badge(passkey)
        end
        p(class: "text-sm text-muted") { "Added #{smart_date(passkey.created_at)}" }
        p(class: "text-sm text-muted") do
          passkey.last_used_at ? "Last used #{smart_date(passkey.last_used_at)}" : "Never used"
        end
      end
      div(class: "settings-value") do
        button_to "Remove", passkey_path(passkey),
          method: :delete,
          data: { turbo_confirm: "Remove #{passkey.nickname}? You won't be able to sign in with this device." },
          class: "btn btn-danger btn-sm"
      end
    end
  end

  # What the authenticator told us about how portable this credential is. It
  # decides whether losing one device loses the account.
  def storage_badge(passkey)
    case passkey.storage
    when :synced then render(Badge.new(:green)) { "Synced" }
    when :syncable then render(Badge.new(:gray)) { "Syncable" }
    when :device_bound then render(Badge.new(:yellow)) { "This device only" }
    end
  end

  def add_row
    div(class: "settings-row") do
      div(class: "settings-label") do
        span(class: "font-medium") { "Add a passkey" }
        p(class: "text-sm text-muted") { description }
      end
      div(class: "settings-value") { add_form }
    end
  end

  def add_form
    form_with url: passkeys_path, method: :post,
      data: {
        controller: "passkey",
        passkey_options_url_value: new_passkey_path,
        turbo_frame: "_top"
      } do |f|
      div(class: "flex gap-2 flex-wrap items-center") do
        f.hidden_field :credential, data: { passkey_target: "credential" }
        f.text_field :nickname, placeholder: "Name this device", class: "form-input form-input-sm"
        f.button "Add passkey", type: "button",
          class: "btn btn-primary btn-sm",
          data: { passkey_target: "submit", action: "passkey#register" }
      end
      p(class: "form-error", hidden: true, data: { passkey_target: "error" })
    end
  end

  # Stay quiet only on proof that the account survives losing a device, which
  # means at least one credential that syncs. Anything else -- device-bound, or
  # an authenticator that told us nothing -- gets the nag.
  def description
    if @passkeys.empty?
      "Sign in with your fingerprint, face, or device PIN instead of a provider."
    elsif @passkeys.none?(&:synced?)
      "None of your passkeys sync between devices. Add another so losing one doesn't lock you out."
    else
      "Add another if you use a device or password manager that isn't covered yet."
    end
  end
end
