class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::CheckBoxTag
  include Phlex::Rails::Helpers::SimpleFormat

  register_value_helper :current_user
  register_value_helper :smart_date
  register_value_helper :pluralize
  register_output_helper :icon
end
