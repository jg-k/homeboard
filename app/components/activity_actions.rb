class ActivityActions < ApplicationComponent
  def initialize(delete_path:, delete_confirm:, edit_path: nil, primary_action: nil)
    @edit_path = edit_path
    @delete_path = delete_path
    @delete_confirm = delete_confirm
    @primary_action = primary_action
  end

  def view_template
    div(class: "flex gap-2") do
      if @primary_action
        link_to @primary_action[:path],
          class: "btn-icon",
          title: @primary_action[:title],
          data: { turbo_frame: "_top" } do
            icon(@primary_action[:icon])
          end
        render_dropdown
      else
        render_edit_button if @edit_path
        render_delete_button
      end
    end
  end

  private

  def render_dropdown
    div(class: "dropdown", data: { controller: "dropdown" }) do
      button(type: "button", class: "btn-icon", title: "More actions",
             data: { action: "dropdown#toggle" }) do
        icon(:more_vertical)
      end
      div(class: "dropdown-menu hidden", data: { dropdown_target: "menu" }) do
        if @edit_path
          link_to @edit_path, class: "dropdown-item",
                  data: { turbo_frame: "_top" } do
            icon(:edit)
            plain " Edit"
          end
        end
        button_to @delete_path, method: :delete,
                  data: { turbo_confirm: @delete_confirm, turbo_frame: "_top" },
                  class: "dropdown-item dropdown-item-danger" do
          icon(:trash)
          plain "Delete"
        end
      end
    end
  end

  def render_edit_button
    link_to @edit_path, class: "btn-icon", title: "Edit", data: { turbo_frame: "_top" } do
      icon(:edit)
    end
  end

  def render_delete_button
    button_to @delete_path, method: :delete, class: "btn-icon-danger", title: "Delete",
      data: { turbo_confirm: @delete_confirm, turbo_frame: "_top" } do
      icon(:trash)
    end
  end
end
