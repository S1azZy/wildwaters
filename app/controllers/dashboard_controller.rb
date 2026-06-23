class DashboardController < ApplicationController
  before_action :require_authentication

  layout "inertia", only: :show

  def show
    render inertia: "Dashboard/Show", props: dashboard_show_props
  end

  private

  def dashboard_show_props
    {
      copy: {
        title: t("dashboard.show.title"),
        heading: t("dashboard.show.heading"),
        signedInAs: t("dashboard.show.signed_in_as", email: current_user.primary_email),
        signOut: t("dashboard.show.sign_out")
      },
      urls: {
        signOut: session_path
      }
    }
  end
end
