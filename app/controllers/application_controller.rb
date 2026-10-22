class ApplicationController < ActionController::Base
  include Pagy::Method

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :safe_return_to

  # Whitelist `return_to` params so they can't be used to redirect to a
  # third-party site or a `javascript:` URL. Only same-origin paths allowed.
  def safe_return_to
    path = params[:return_to].to_s
    return nil if path.blank?
    return nil unless path.start_with?("/")
    return nil if path.start_with?("//")
    path
  end
end
