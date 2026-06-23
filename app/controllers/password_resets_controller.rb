class PasswordResetsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]

  layout "inertia", only: %i[new edit update]

  def new
    render inertia: "PasswordResets/New", props: password_reset_new_props
  end

  def create
    Auth::RequestPasswordReset.call(input: password_reset_request_params.to_h)

    redirect_to new_session_path, notice: t("auth.password_resets.create.success")
  end

  def edit
    render inertia: "PasswordResets/Edit", props: password_reset_edit_props
  end

  def update
    result = Auth::ResetPassword.call(input: password_reset_update_params.to_h.merge(token: params[:token]))

    if result.success?
      redirect_to new_session_path, notice: t("auth.password_resets.update.success")
    else
      render inertia: "PasswordResets/Edit",
        props: password_reset_edit_props(form_error: t("auth.password_resets.update.failure")),
        status: :unprocessable_content
    end
  end

  private

  def password_reset_request_params
    params.expect(password_reset: %i[email])
  end

  def password_reset_update_params
    params.expect(password_reset: %i[password password_confirmation])
  end

  def password_reset_new_props
    {
      auth: auth_shell_props(
        variant: "recovery",
        panel_label: "Secure account recovery",
        namespace: "auth.password_resets.new",
        alternate_prompt: t("auth.password_resets.new.sign_in_prompt"),
        alternate_label: t("auth.password_resets.new.sign_in_link"),
        alternate_url: new_session_path
      ),
      copy: {
        cardHeading: t("auth.password_resets.new.card_heading"),
        cardSupporting: t("auth.password_resets.new.card_supporting"),
        submit: t("auth.password_resets.new.submit")
      },
      fields: {
        email: field_props("auth.fields.email", placeholder: "auth.fields.email_placeholder")
      },
      urls: {
        submit: password_reset_path
      },
      values: {
        email: params.dig(:password_reset, :email)&.strip&.downcase
      }
    }
  end

  def password_reset_edit_props(form_error: nil)
    {
      auth: auth_shell_props(
        variant: "recovery",
        panel_label: "Secure account recovery",
        namespace: "auth.password_resets.edit",
        alternate_prompt: t("auth.password_resets.edit.sign_in_prompt"),
        alternate_label: t("auth.password_resets.edit.sign_in_link"),
        alternate_url: new_session_path
      ),
      copy: {
        cardHeading: t("auth.password_resets.edit.card_heading"),
        cardSupporting: t("auth.password_resets.edit.card_supporting"),
        submit: t("auth.password_resets.edit.submit")
      },
      fields: {
        password: field_props("auth.fields.password", placeholder: "auth.fields.password_placeholder"),
        passwordConfirmation: field_props("auth.fields.password_confirmation", placeholder: "auth.fields.password_placeholder")
      },
      formError: form_error,
      urls: {
        submit: password_reset_token_path(params[:token])
      }
    }
  end

  def auth_shell_props(variant:, panel_label:, namespace:, alternate_prompt:, alternate_label:, alternate_url:)
    {
      variant:,
      eyebrow: t("#{namespace}.eyebrow"),
      title: t("#{namespace}.heading"),
      description: t("#{namespace}.subheading"),
      panelLabel: panel_label,
      alternatePrompt: alternate_prompt,
      alternateLabel: alternate_label,
      alternateUrl: alternate_url
    }
  end

  def field_props(label_key, placeholder: nil)
    props = { label: t(label_key) }
    props[:placeholder] = t(placeholder) if placeholder
    props
  end

  def redirect_authenticated_user
    redirect_to dashboard_path if authenticated?
  end
end
