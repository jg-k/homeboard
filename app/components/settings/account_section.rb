class Settings::AccountSection < ApplicationComponent
  def view_template
    render SettingsSection.new(title: "Account") do
      render SettingsRow.new(title: "Email") do
        span { current_user.email }
      end

      render SettingsRow.new(title: "Sign-in method") do
        if current_user.provider.present?
          render Badge.new(:gray) { current_user.provider.titleize.gsub("Oauth2", "OAuth") }
        else
          render Badge.new(:gray) { "Email" }
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
