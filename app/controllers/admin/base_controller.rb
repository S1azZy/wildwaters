module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def admin_navigation(current:)
      {
        sections: [
          {
            key: "primary",
            items: [
              admin_navigation_item(
                key: "dashboard",
                icon: "dashboard",
                label: t("admin.navigation.dashboard"),
                url: admin_root_path,
                current: current == "dashboard"
              ),
              admin_navigation_item(
                key: "service_actions",
                icon: "wrench",
                label: t("admin.navigation.service_actions"),
                url: admin_service_actions_path,
                current: current == "service_actions"
              )
            ]
          },
          {
            key: "models",
            label: t("admin.navigation.models"),
            items: [
              admin_navigation_item(
                key: "users",
                icon: "users",
                label: t("admin.navigation.users"),
                url: admin_users_path,
                current: current == "users"
              ),
              admin_navigation_item(
                key: "regions",
                icon: "regions",
                label: t("admin.navigation.regions"),
                url: admin_regions_path,
                current: current == "regions"
              )
            ]
          }
        ]
      }
    end

    def admin_navigation_item(key:, icon:, label:, url:, current:)
      {
        key:,
        icon:,
        label:,
        url:,
        current:
      }
    end

    def require_admin!
      return redirect_to(main_app.new_session_path, alert: t("auth.sessions.require_authentication")) unless authenticated?
      return if current_user.admin?

      redirect_to main_app.root_path, alert: t("admin.authorization.required")
    end
  end
end
