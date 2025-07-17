class ApplicationController < ActionController::Base
  # Removed overly restrictive browser check that was causing 406 errors
  # allow_browser versions: :modern

  # Configure Devise to permit additional parameters
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Temporary admin promotion method (remove after use)
  def promote_to_admin
    if user_signed_in?
      current_user.update!(admin: true)
      redirect_to admin_root_path, notice: "You are now an admin! Welcome to the admin panel."
    else
      redirect_to new_user_session_path, alert: "Please sign in first."
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
end
