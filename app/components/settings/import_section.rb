class Settings::ImportSection < ApplicationComponent
  def view_template
    render SettingsSection.new(title: "Import") do
      div(class: "settings-row") do
        div(class: "settings-label") do
          span(class: "font-medium") { "Outdoor climbing log" }
          p(class: "text-sm text-muted") { "Import outdoor logbook from:" }
          ul(class: "text-sm text-muted list-simple") do
            li { "theCrag CSV export" }
            li { "UKC DLOG CSV export" }
          end
        end
        div(class: "settings-value") do
          link_to "Import", new_crag_ascent_import_path, class: "btn btn-primary btn-sm"
        end
      end

      render SettingsRow.new(title: "Clear imported data", description: "Delete all imported outdoor ascents. This cannot be undone.") do
        button_to "Clear all", clear_imported_ascents_settings_path, method: :delete,
          class: "btn btn-danger btn-sm",
          data: { turbo_confirm: "Are you sure? This will delete all your imported outdoor ascents." }
      end
    end
  end
end
