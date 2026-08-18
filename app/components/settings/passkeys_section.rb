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

  def description
    if @passkeys.any?
      "Register a second device so losing one doesn't lock you out."
    else
      "Sign in with your fingerprint, face, or device PIN instead of a provider."
    end
  end
end
