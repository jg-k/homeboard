class Settings::ExportSection < ApplicationComponent
  def view_template
    render SettingsSection.new(title: "Export") do
      render SettingsRow.new(title: "JSON", description: "All activities in a single JSON file.") do
        link_to "Export JSON", export_json_settings_path, class: "btn btn-primary btn-sm"
      end
      render SettingsRow.new(title: "CSV", description: "ZIP archive with one CSV per activity type.") do
        link_to "Export CSV", export_csv_settings_path, class: "btn btn-primary btn-sm"
      end
    end
  end
end
