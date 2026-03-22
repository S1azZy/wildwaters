class ApplicationComponent < ViewComponent::Base
  private

  def normalize_option(value, allowed:, error_prefix:)
    candidate = value.to_sym
    return candidate if allowed.include?(candidate)

    raise ArgumentError, "#{error_prefix}: #{value.inspect}"
  end

  def ensure_accessible_name!(label:, aria_label:, component_name:)
    return if label.present? || aria_label.present?

    raise ArgumentError, "#{component_name} requires either a visible label or aria_label"
  end

  def normalized_dom_id(value, fallback:)
    token = value.to_s.gsub(/[\[\]]+/, "_").gsub(/[^a-zA-Z0-9_-]+/, "_").gsub(/_+/, "_").delete_suffix("_")

    token.presence || fallback
  end
end
