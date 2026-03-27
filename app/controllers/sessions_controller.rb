class SessionsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]
  before_action :require_authentication, only: :destroy

  def new; end

  def create
    result = Auth::AuthenticateUser.call(input: session_params.to_h)

    if result.success?
      user = result.value![:user]
      user_identity = result.value![:user_identity]

      issue_session_for!(user, user_identity)

      redirect_to root_path, notice: t("auth.sessions.create.success")
    else
      @error_code = result.failure[:code]
      flash.now[:alert] = t("auth.sessions.create.failure")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    Auth::LogoutUser.call(input: { session: current_session })
    clear_current_session!

    redirect_to new_session_path, notice: t("auth.sessions.destroy.success"), status: :see_other
  end

  private

  def session_params
    params.expect(session: %i[email password])
  end

  def redirect_authenticated_user
    redirect_to root_path if authenticated?
  end
end
