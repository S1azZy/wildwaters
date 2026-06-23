class RegistrationsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]

  layout "inertia", only: %i[new create]

  def new
    render inertia: "Registrations/New", props: registration_new_props
  end

  def create
    result = Auth::RegisterUser.call(input: registration_params.to_h)

    if result.success?
      user = result.value![:user]
      user_identity = result.value![:user_identity]

      issue_session_for!(user, user_identity)

      redirect_to dashboard_path, notice: t("auth.registrations.create.success")
    else
      render inertia: "Registrations/New",
        props: registration_new_props(form_error: registration_error_message(result.failure[:errors])),
        status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.expect(registration: %i[email password password_confirmation locale])
  end

  def registration_new_props(form_error: nil)
    {
      auth: auth_shell_props(
        variant: "registration",
        panel_label: "Field kit setup",
        namespace: "auth.registrations.new",
        alternate_prompt: t("auth.registrations.new.sign_in_prompt"),
        alternate_label: t("auth.registrations.new.sign_in_link"),
        alternate_url: new_session_path
      ),
      copy: {
        cardHeading: t("auth.registrations.new.card_heading"),
        cardSupporting: t("auth.registrations.new.card_supporting"),
        localeHint: t("auth.registrations.new.locale_hint"),
        submit: t("auth.registrations.new.submit")
      },
      fields: {
        email: field_props("auth.fields.email", placeholder: "auth.fields.email_placeholder"),
        locale: field_props("auth.fields.locale"),
        password: field_props("auth.fields.password", placeholder: "auth.fields.password_placeholder"),
        passwordConfirmation: field_props("auth.fields.password_confirmation", placeholder: "auth.fields.password_placeholder")
      },
      formError: form_error,
      localeOptions: I18n.available_locales.map do |locale|
        { label: t("auth.locales.#{locale}"), value: locale.to_s }
      end,
      urls: {
        submit: registration_path
      },
      values: {
        email: params.dig(:registration, :email)&.strip&.downcase,
        locale: selected_locale
      }
    }
  end

  def registration_error_message(errors)
    errors.to_h.values.flatten.join(", ")
  end

  def selected_locale
    locale = params.dig(:registration, :locale).presence || I18n.default_locale.to_s
    I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale.to_s
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
