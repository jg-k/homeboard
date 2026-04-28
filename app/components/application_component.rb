class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::CheckBoxTag

  register_value_helper :current_user
  register_output_helper :icon
end
