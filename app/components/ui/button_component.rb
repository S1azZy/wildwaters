module Ui
  class ButtonComponent < ApplicationComponent
    VARIANTS = %i[primary secondary outlined inverted].freeze
    SIZES = %i[sm md].freeze

    attr_reader :variant, :size, :href

    def initialize(variant: :primary, size: :md, href: nil)
      @variant = validate_variant(variant)
      @size = validate_size(size)
      @href = href
    end

    def link?
      href.present?
    end

    def tag_name
      link? ? :a : :button
    end

    private

    def validate_variant(value)
      candidate = value.to_sym
      return candidate if VARIANTS.include?(candidate)

      raise ArgumentError, "Unknown button variant: #{value.inspect}"
    end

    def validate_size(value)
      candidate = value.to_sym
      return candidate if SIZES.include?(candidate)

      raise ArgumentError, "Unknown button size: #{value.inspect}"
    end
  end
end
