class Settings::IntegrationsSection < ApplicationComponent
  def initialize(current_user:)
    @current_user = current_user
  end

  def view_template
    render SettingsSection.new(title: "Integrations") do
      boardsesh_row
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
end
