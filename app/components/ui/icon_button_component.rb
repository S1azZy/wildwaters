module Ui
  class IconButtonComponent < ApplicationComponent
    VARIANTS = %i[secondary ghost primary].freeze
    SIZES = %i[sm md].freeze
    SHAPES = %i[circle rounded].freeze

    attr_reader :label, :variant, :size, :shape, :href, :disabled

    def initialize(label:, variant: :secondary, size: :md, shape: :circle, href: nil, disabled: false)
      raise ArgumentError, "Icon button requires an accessible label" if label.blank?

      @label = label
      @variant = normalize_option(variant, allowed: VARIANTS, error_prefix: "Unknown icon button variant")
      @size = normalize_option(size, allowed: SIZES, error_prefix: "Unknown icon button size")
      @shape = normalize_option(shape, allowed: SHAPES, error_prefix: "Unknown icon button shape")
      @href = href
      @disabled = disabled
    end

    def link?
      href.present? && !disabled
    end
  end
end
