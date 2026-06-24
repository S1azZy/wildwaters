class SessionsController < ApplicationController
  include AuthPageProps

  before_action :redirect_authenticated_user, only: %i[new create]
  before_action :require_authentication, only: :destroy

  layout "inertia", only: %i[new create]

  def new
    render inertia: "Sessions/New", props: session_new_props
  end

  def create
    result = Auth::AuthenticateUser.call(input: session_params.to_h)

    if result.success?
      user = result.value![:user]
      user_identity = result.value![:user_identity]

      issue_session_for!(user, user_identity)

      if request.headers["X-Inertia"].present?
        flash[:notice] = t("auth.sessions.create.success")
        return inertia_location(root_path)
      end

      redirect_to root_path, notice: t("auth.sessions.create.success")
    else
      render inertia: "Sessions/New",
        props: session_new_props(form_error: t("auth.sessions.create.failure")),
        status: :unprocessable_content
    end
  end

  def destroy
    Auth::LogoutUser.call(input: { session: current_session })
    clear_current_session!

    if request.headers["X-Inertia"].present?
      flash[:notice] = t("auth.sessions.destroy.success")
      return inertia_location(new_session_path)
    end

    redirect_to new_session_path, notice: t("auth.sessions.destroy.success"), status: :see_other
  end

  private

  def session_params
    params.expect(session: %i[email password])
  end

  def session_new_props(form_error: nil)
    {
      auth: auth_shell_props(
        variant: "session",
        panel_label_key: "auth.sessions.new.panel_label",
        namespace: "auth.sessions.new",
        alternate_prompt: t("auth.sessions.new.sign_up_prompt"),
        alternate_label: t("auth.sessions.new.sign_up_link"),
        alternate_url: new_registration_path
      ),
      copy: {
        cardHeading: t("auth.sessions.new.card_heading"),
        cardSupporting: t("auth.sessions.new.card_supporting"),
        forgotPassword: t("auth.sessions.new.forgot_password"),
        submit: t("auth.sessions.new.submit")
      },
      fields: {
        email: field_props("auth.fields.email", placeholder: "auth.fields.email_placeholder"),
        password: field_props("auth.fields.password", placeholder: "auth.fields.password_placeholder")
      },
      formError: form_error,
      urls: {
        forgotPassword: new_password_reset_path,
        submit: session_path
      },
      values: {
        email: params.dig(:session, :email)&.strip&.downcase
      }
    }
  end

  def redirect_authenticated_user
    redirect_to root_path if authenticated?
  end
end
