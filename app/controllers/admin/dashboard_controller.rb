module Admin
  class DashboardController < BaseController
    layout "inertia", only: :index

    def index
      render inertia: "Admin/Dashboard/Index", props: dashboard_props
    end

    private

    def dashboard_props
      {
        copy: {
          title: t("admin.dashboard.index.title"),
          heading: t("admin.dashboard.index.heading"),
          description: t("admin.dashboard.index.description"),
          toolbarLabel: t("admin.shell.toolbar_label"),
          placeholderTitle: t("admin.dashboard.index.placeholder_title"),
          placeholderDescription: t("admin.dashboard.index.placeholder_description")
        },
        navigation: admin_navigation(current: "dashboard")
      }
    end
  end
end
