module Ui
  class CardComponent < ApplicationComponent
    VARIANTS = %i[default elevated ghost].freeze
    PADDING = %i[sm md lg].freeze

    attr_reader :variant, :padding, :tag

    def initialize(variant: :default, padding: :md, tag: :div)
      @variant = normalize_option(variant, allowed: VARIANTS, error_prefix: "Unknown card variant")
      @padding = normalize_option(padding, allowed: PADDING, error_prefix: "Unknown card padding")
      @tag = tag.to_sym
    end
  end
end
