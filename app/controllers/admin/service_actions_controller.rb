module Admin
  class ServiceActionsController < BaseController
    layout "inertia", only: :index

    def index
      render inertia: "Admin/ServiceActions/Index", props: service_actions_props
    end

    private

    def service_actions_props
      {
        copy: {
          title: t("admin.service_actions.index.title"),
          heading: t("admin.service_actions.index.heading"),
          description: t("admin.service_actions.index.description"),
          toolbarLabel: t("admin.shell.toolbar_label"),
          placeholderTitle: t("admin.service_actions.index.placeholder_title"),
          placeholderDescription: t("admin.service_actions.index.placeholder_description")
        },
        navigation: admin_navigation(current: "service_actions"),
        urls: {
          serviceActions: admin_service_actions_path
        }
      }
    end
  end
end
