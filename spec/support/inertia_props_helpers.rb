# frozen_string_literal: true

module InertiaPropsHelpers
  def expect_auth_page_contract!(component:, expected_props:, status: :ok, locale: I18n.locale)
    expect(response).to have_http_status(status)
    expect(inertia).to be_inertia_response
    expect(inertia).to render_component(component)
    expect(inertia.props.keys).to contain_exactly(*expected_props.keys.map(&:to_s), "errors", "shell")
    expect(inertia.props.fetch("errors")).to eq({})
    expect(inertia).to have_props(expected_props.merge(shell: expected_shell_props(locale:)))
    expect(nested_keys(inertia.props)).not_to include(*auth_sensitive_prop_keys)
  end

  def expect_inertia_runtime_document!
    expect(response.body).to include(I18n.t("frontend.javascript_required"))
    expect(response.body).to include('href="/vite-test/assets/application-', 'type="module"')
  end

  def expected_shell_labels(locale: I18n.locale)
    {
      brandName: I18n.t("layouts.header.brand_name", locale:),
      brandTagline: I18n.t("layouts.header.brand_tagline", locale:),
      explore: I18n.t("layouts.header.explore", locale:),
      primaryMobileNavigation: I18n.t("layouts.header.primary_mobile_navigation", locale:),
      primaryNavigation: I18n.t("layouts.header.primary_navigation", locale:),
      profile: I18n.t("layouts.header.profile", locale:),
      signIn: I18n.t("layouts.header.sign_in", locale:)
    }
  end

  def expected_shell_urls
    {
      dashboard: dashboard_path,
      explore: root_path,
      signIn: new_session_path
    }
  end

  def expected_shell_props(locale: I18n.locale, authenticated: false)
    {
      authenticated:,
      labels: expected_shell_labels(locale:),
      urls: expected_shell_urls
    }
  end

  def auth_shell_props(variant:, panel_label_key:, namespace:, alternate_prompt:, alternate_label:, alternate_url:)
    {
      variant:,
      eyebrow: I18n.t("#{namespace}.eyebrow"),
      title: I18n.t("#{namespace}.heading"),
      description: I18n.t("#{namespace}.subheading"),
      panelLabel: I18n.t(panel_label_key),
      alternatePrompt: alternate_prompt,
      alternateLabel: alternate_label,
      alternateUrl: alternate_url
    }
  end

  def field_props(label_key, placeholder: nil)
    props = { label: I18n.t(label_key) }
    props[:placeholder] = I18n.t(placeholder) if placeholder
    props
  end

  def nested_keys(value)
    case value
    when Hash
      value.flat_map { |key, nested_value| [ key, *nested_keys(nested_value) ] }
    when Array
      value.flat_map { |nested_value| nested_keys(nested_value) }
    else
      []
    end
  end

  def auth_sensitive_prop_keys
    %w[
      credential
      credentials
      current_user
      identity
      policy
      primary_email
      reset_token
      role
      session
      status
      token
      user
    ]
  end
end

RSpec.configure do |config|
  config.include InertiaPropsHelpers, type: :request
end
