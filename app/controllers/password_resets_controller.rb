class PasswordResetsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]

  def new; end

  def create
    Auth::RequestPasswordReset.call(input: password_reset_request_params.to_h)

    redirect_to new_session_path, notice: t("auth.password_resets.create.success")
  end

  def edit
    @token = params[:token]
  end

  def update
    result = Auth::ResetPassword.call(input: password_reset_update_params.to_h.merge(token: params[:token]))

    if result.success?
      redirect_to new_session_path, notice: t("auth.password_resets.update.success")
    else
      @token = params[:token]
      flash.now[:alert] = t("auth.password_resets.update.failure")
      render :edit, status: :unprocessable_content
    end
  end

  private

  def password_reset_request_params
    params.expect(password_reset: %i[email])
  end

  def password_reset_update_params
    params.expect(password_reset: %i[password password_confirmation])
  end

  def redirect_authenticated_user
    redirect_to dashboard_path if authenticated?
  end
end
