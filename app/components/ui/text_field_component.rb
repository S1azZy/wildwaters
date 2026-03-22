module Ui
  class TextFieldComponent < ApplicationComponent
    SIZES = %i[sm md].freeze

    renders_one :leading_icon

    attr_reader :name,
                :label,
                :aria_label,
                :value,
                :placeholder,
                :supporting_text,
                :error,
                :size,
                :type,
                :disabled,
                :input_id

    def initialize(
      attributes = nil,
      name: nil,
      label: nil,
      aria_label: nil,
      value: nil,
      placeholder: nil,
      supporting_text: nil,
      error: nil,
      size: :md,
      type: :text,
      disabled: false,
      input_id: nil
    )
      attributes = attributes&.to_h&.symbolize_keys || {}
      name = name || attributes[:name]
      label = attributes[:label] if label.nil?
      aria_label = attributes[:aria_label] if aria_label.nil?
      value = attributes[:value] if value.nil?
      placeholder = attributes[:placeholder] if placeholder.nil?
      supporting_text = attributes[:supporting_text] if supporting_text.nil?
      error = attributes[:error] if error.nil?
      size = attributes[:size] if size == :md && attributes.key?(:size)
      type = attributes[:type] if type == :text && attributes.key?(:type)
      disabled = attributes[:disabled] if disabled == false && attributes.key?(:disabled)
      input_id = attributes[:input_id] if input_id.nil?

      raise ArgumentError, "missing keyword: name" if name.nil?

      ensure_accessible_name!(label:, aria_label:, component_name: "Text field")

      @name = name
      @label = label
      @aria_label = aria_label
      @value = value
      @placeholder = placeholder
      @supporting_text = supporting_text
      @error = error
      @size = normalize_option(size, allowed: SIZES, error_prefix: "Unknown text field size")
      @type = type.to_sym
      @disabled = disabled
      @input_id = input_id.presence || generated_input_id(prefix: "text_field", value: name, fallback: "field")
    end

    def state
      return :error if error.present?
      return :disabled if disabled

      :default
    end

    def described_by_id
      return if supporting_copy.blank?

      "#{input_id}_description"
    end

    def supporting_copy
      error.presence || supporting_text
    end

    def supporting_copy_data_ui
      error.present? ? "text-field-error" : "text-field-supporting-text"
    end
  end
end
