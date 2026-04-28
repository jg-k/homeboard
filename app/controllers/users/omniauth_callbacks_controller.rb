class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2, :entra_id ]

  def google_oauth2
    handle_oauth("Google")
  end

  def entra_id
    handle_oauth("Microsoft")
  end

  def failure
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  private

  def handle_oauth(kind)
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    else
      session["devise.oauth_data"] = auth.except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
