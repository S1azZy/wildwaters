module Ui
  class AuthShellComponent < ApplicationComponent
    VARIANTS = %i[session registration recovery].freeze

    renders_one :panel

    attr_reader :variant,
                :eyebrow,
                :title,
                :description,
                :alternate_prompt,
                :alternate_label,
                :alternate_path,
                :footer_author,
                :footer_note

    def initialize(
      variant:,
      eyebrow:,
      title:,
      description:,
      alternate_prompt:,
      alternate_label:,
      alternate_path:,
      footer_author:,
      footer_note:
    )
      @variant = normalize_option(variant, allowed: VARIANTS, error_prefix: "Unknown auth shell variant")
      @eyebrow = eyebrow
      @title = title
      @description = description
      @alternate_prompt = alternate_prompt
      @alternate_label = alternate_label
      @alternate_path = alternate_path
      @footer_author = footer_author
      @footer_note = footer_note
    end

    def shell_class
      "auth-shell auth-shell--#{variant}"
    end

    def panel_label
      case variant
      when :session
        "Basecamp access"
      when :registration
        "Field kit setup"
      when :recovery
        "Secure account recovery"
      end
    end
  end
end
