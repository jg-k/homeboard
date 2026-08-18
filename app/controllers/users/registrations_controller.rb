class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :display_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :display_name ])
  end
end
