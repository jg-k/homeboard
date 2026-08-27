class Settings::IntegrationsSection < ApplicationComponent
  def initialize(current_user:)
    @current_user = current_user
  end

  def view_template
    render SettingsSection.new(title: "Integrations") do
      boardsesh_row
      thecrag_row
      ukc_row
    end
  end

  private

  def boardsesh_row
    if @current_user.boardsesh_user_id.present?
      boardsesh_connected_row
    else
      boardsesh_disconnected_row
    end
  end

  def boardsesh_disconnected_row
    div(class: "settings-row") do
      div(class: "settings-label") do
        span(class: "font-medium") { "Boardsesh" }
        p(class: "text-sm text-muted") { "Import your logbook from Boardsesh (Kilter, Tension)." }
      end
      div(class: "settings-value") do
        link_to "Connect", new_boardsesh_connection_path, class: "btn btn-primary btn-sm"
      end
    end
  end

  def boardsesh_connected_row
    div(class: "settings-row") do
      div(class: "settings-label") do
        span(class: "font-medium") { "Boardsesh" }
        p(class: "text-sm text-muted") do
          plain "User ID: "
          strong { @current_user.boardsesh_user_id }
        end
        if @current_user.boardsesh_last_synced_at
          p(class: "text-sm text-muted") { "Last synced: #{helpers.time_ago_in_words(@current_user.boardsesh_last_synced_at)} ago" }
        end
      end
      div(class: "settings-value") do
        div(class: "flex gap-2 flex-wrap") do
          button_to "Sync", boardsesh_sync_path, method: :post, class: "btn btn-primary btn-sm"
          button_to "Disconnect", boardsesh_connection_path, method: :delete, class: "btn btn-outline btn-sm",
            data: { turbo_confirm: "Disconnect your Boardsesh account?" }
          button_to "Clear data", boardsesh_data_path, method: :delete, class: "btn btn-danger btn-sm",
            data: { turbo_confirm: "Delete all imported Boardsesh climbs? This cannot be undone." }
        end
      end
    end
  end

  def thecrag_row
    div(class: "settings-row") do
      div(class: "settings-label") do
        span(class: "font-medium") { "theCrag" }
        p(class: "text-sm text-muted") { "Sync your latest ascents from theCrag." }
        if @current_user.thecrag_synced_at
          p(class: "text-sm text-muted") { "Last synced: #{helpers.time_ago_in_words(@current_user.thecrag_synced_at)} ago" }
        end
        if @current_user.thecrag_sync_error.present?
          p(class: "text-sm text-danger") { "Syncing stopped: #{@current_user.thecrag_sync_error}" }
        end
      end
      div(class: "settings-value") do
        form_with url: sync_thecrag_crag_ascent_imports_path, method: :post, data: { turbo_frame: "_top" } do |f|
          div(class: "stack-sm") do
            div do
              f.label :thecrag_username, "Username", class: "form-label"
              f.text_field :thecrag_username, value: @current_user.thecrag_username, placeholder: "username", class: "form-input form-input-sm"
            end
            div do
              div(class: "flex gap-2 items-center mb-1") do
                f.label :thecrag_api_key, "API key", class: "form-label mb-0"
                render Badge.new(:green) { "Saved" } if @current_user.thecrag_api_key.present?
              end
              # A plain field, not a password one: "new-password" stops the site
              # password being autofilled but invites a manager to generate one
              # instead, and a generated password saved here reads as a valid key
              # until theCrag rejects it. Nothing is prefilled, so nothing leaks.
              f.text_field :thecrag_api_key,
                value: "",
                autocomplete: "off",
                placeholder: api_key_placeholder,
                data: { "1p-ignore": true, lpignore: true, "form-type": "other" },
                class: "form-input form-input-sm"
            end
            p(class: "text-xs text-muted") do
              plain "Only paying theCrag supporters can issue an API key. If you are one, "
              plain "find it on theCrag under Settings › API Keys. "
              plain "With a key we read your logbook through their API instead of you "
              plain "exporting and importing a CSV by hand."
            end
            div do
              f.submit thecrag_connected? ? "Sync" : "Connect & sync", class: "btn btn-primary btn-sm"
            end
          end
        end
      end
    end
  end

  def api_key_placeholder
    @current_user.thecrag_api_key.present? ? "Paste a new key to replace the saved one" : "theCrag API key (optional)"
  end

  def thecrag_connected?
    @current_user.thecrag_username.present? || @current_user.thecrag_api_key.present?
  end

  def ukc_row
    return if Rails.env.production?

    div(class: "settings-row") do
      div(class: "settings-label") do
        span(class: "font-medium") { "UKC" }
        p(class: "text-sm text-muted") { "Sync your latest ascents from UK Climbing." }
        if @current_user.ukc_synced_at
          p(class: "text-sm text-muted") { "Last synced: #{helpers.time_ago_in_words(@current_user.ukc_synced_at)} ago" }
        end
      end
      div(class: "settings-value") do
        form_with url: sync_ukc_crag_ascent_imports_path, method: :post, data: { turbo_frame: "_top" } do |f|
          div(class: "flex gap-2 flex-wrap items-center") do
            f.text_field :ukc_user_id, value: @current_user.ukc_user_id, placeholder: "user ID or logbook URL", class: "form-input form-input-sm", required: true
            f.submit @current_user.ukc_user_id.present? ? "Sync" : "Connect & sync", class: "btn btn-primary btn-sm"
          end
        end
      end
    end
  end
end
