class ApplicationController < ActionController::Base
  # Removed overly restrictive browser check that was causing 406 errors
  # allow_browser versions: :modern

  # Configure Devise to permit additional parameters
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
end
