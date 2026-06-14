class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  inertia_share do
    {
      shell: {
        authenticated: authenticated?,
        labels: {
          brandName: t("layouts.header.brand_name"),
          brandTagline: t("layouts.header.brand_tagline"),
          explore: t("layouts.header.explore"),
          profile: t("layouts.header.profile"),
          signIn: t("layouts.header.sign_in")
        },
        urls: {
          dashboard: dashboard_path,
          explore: root_path,
          signIn: new_session_path
        }
      }
    }
  end
end
