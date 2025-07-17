class ApplicationController < ActionController::Base
  # Removed overly restrictive browser check that was causing 406 errors
  # allow_browser versions: :modern
end
