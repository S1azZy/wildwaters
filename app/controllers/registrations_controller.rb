class RegistrationsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]

  def new; end

  def create
    result = Auth::RegisterUser.call(input: registration_params.to_h)

    if result.success?
      user = result.value![:user]
      user_identity = result.value![:user_identity]

      issue_session_for!(user, user_identity)

      redirect_to dashboard_path, notice: t("auth.registrations.create.success")
    else
      @errors = result.failure[:errors]
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(registration: %i[email password password_confirmation locale])
  end

  def redirect_authenticated_user
    redirect_to dashboard_path if authenticated?
  end
end
