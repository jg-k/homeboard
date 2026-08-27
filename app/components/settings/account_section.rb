class Settings::AccountSection < ApplicationComponent
  def view_template
    render SettingsSection.new(title: "Account") do
      render SettingsRow.new(title: "Display name", description: "How other climbers find and follow you") do
        span { current_user.display_name }
      end

      render SettingsRow.new(title: "Email") do
        span { current_user.email.presence || "Not set" }
      end

      render SettingsRow.new(title: "Sign-in method") do
        if current_user.provider.present?
          render Badge.new(:gray) { current_user.oauth_provider_name }
        elsif current_user.email.present?
          render Badge.new(:gray) { "Email" }
        else
          render Badge.new(:gray) { "Passkey" }
        end
      end

      if current_user.provider.blank?
        render SettingsRow.new(title: "Connect a sign-in", description: "Add Google or Microsoft as another way to sign in") do
          div(class: "flex gap-2 flex-wrap") do
            button_to "Connect Google", user_google_oauth2_omniauth_authorize_path,
              method: :post, data: { turbo: false }, class: "btn btn-outline btn-sm"
            button_to "Connect Microsoft", user_entra_id_omniauth_authorize_path,
              method: :post, data: { turbo: false }, class: "btn btn-outline btn-sm"
          end
        end
      end

      render SettingsRow.new(title: "Member since") do
        span { current_user.created_at.strftime("%B %d, %Y") }
      end

      render SettingsRow.new(title: "Allow followers", description: "Let other climbers follow you") do
        form_with url: toggle_allow_follows_settings_path, method: :patch, data: { turbo_frame: "_top" } do |f|
          label(class: "toggle") do
            check_box_tag :allow_follows, "1", current_user.allow_follows, onchange: "this.form.requestSubmit()"
            span(class: "toggle-slider")
          end
        end
      end

      render SettingsRow.new(title: "Delete account", description: "Permanently delete your account and all data") do
        button_to "Delete Account", user_registration_path,
          method: :delete,
          data: { turbo_confirm: "Are you sure? This will permanently delete your account and all your data. This cannot be undone." },
          class: "btn btn-danger btn-sm"
      end
    end
  end
end
