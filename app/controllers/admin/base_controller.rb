module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      return redirect_to(main_app.new_session_path, alert: t("auth.sessions.require_authentication")) unless authenticated?
      return if current_user.admin?

      redirect_to main_app.root_path, alert: t("admin.authorization.required")
    end
  end
end
