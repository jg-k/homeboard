class ActivityActions < ApplicationComponent
  def initialize(comment_path:, edit_path: nil, delete_path: nil, delete_confirm: nil, primary_action: nil)
    @comment_path = comment_path
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
      end
      render_dropdown
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
        link_to @comment_path, class: "dropdown-item",
                data: { turbo_frame: "_top" } do
          icon(:message_circle)
          plain " Add comment"
        end
        if @edit_path
          link_to @edit_path, class: "dropdown-item",
                  data: { turbo_frame: "_top" } do
            icon(:edit)
            plain " Edit"
          end
        end
        if @delete_path
          button_to @delete_path, method: :delete,
                    data: { turbo_confirm: @delete_confirm, turbo_frame: "_top" },
                    class: "dropdown-item dropdown-item-danger" do
            icon(:trash)
            plain " Delete"
          end
        end
      end
    end
  end
end
