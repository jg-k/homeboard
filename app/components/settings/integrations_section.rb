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
      end
      div(class: "settings-value") do
        form_with url: sync_thecrag_crag_ascent_imports_path, method: :post, data: { turbo_frame: "_top" } do |f|
          div(class: "flex gap-2 flex-wrap items-center") do
            f.text_field :thecrag_username, value: @current_user.thecrag_username, placeholder: "username", class: "form-input form-input-sm", required: true
            f.submit @current_user.thecrag_username.present? ? "Sync" : "Connect & sync", class: "btn btn-primary btn-sm"
          end
        end
      end
    end
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
