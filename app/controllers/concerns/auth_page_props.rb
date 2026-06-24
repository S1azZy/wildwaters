module AuthPageProps
  extend ActiveSupport::Concern

  private

  def auth_shell_props(variant:, panel_label_key:, namespace:, alternate_prompt:, alternate_label:, alternate_url:)
    {
      variant:,
      eyebrow: t("#{namespace}.eyebrow"),
      title: t("#{namespace}.heading"),
      description: t("#{namespace}.subheading"),
      panelLabel: t(panel_label_key),
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
end
