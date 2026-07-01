class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  around_action :use_request_locale

  # Only allow modern browsers supporting webp images, web push, badges, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  inertia_share do
    {
      shell: {
        authenticated: authenticated?,
        labels: {
          brandName: t("layouts.header.brand_name"),
          brandTagline: t("layouts.header.brand_tagline"),
          explore: t("layouts.header.explore"),
          primaryMobileNavigation: t("layouts.header.primary_mobile_navigation"),
          primaryNavigation: t("layouts.header.primary_navigation"),
          accountMenu: t("layouts.header.account_menu"),
          admin: t("layouts.header.admin"),
          mainPage: t("layouts.header.main_page"),
          profile: t("layouts.header.profile"),
          signOut: t("layouts.header.sign_out"),
          signIn: t("layouts.header.sign_in")
        },
        urls: shell_urls
      }
    }
  end

  private

  def shell_urls
    urls = {
      dashboard: dashboard_path,
      explore: root_path,
      signIn: new_session_path,
      signOut: session_path
    }

    urls[:admin] = admin_service_actions_path if current_user&.admin?
    urls
  end

  def use_request_locale(&action)
    I18n.with_locale(current_user&.locale || I18n.default_locale, &action)
  end
end
