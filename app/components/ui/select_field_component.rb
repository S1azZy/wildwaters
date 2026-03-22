module Ui
  class SelectFieldComponent < ApplicationComponent
    SIZES = %i[sm md].freeze

    attr_reader :name,
                :label,
                :aria_label,
                :options,
                :prompt,
                :selected,
                :supporting_text,
                :error,
                :size,
                :disabled,
                :input_id

    def initialize(
      attributes = nil,
      name: nil,
      options: nil,
      label: nil,
      aria_label: nil,
      prompt: nil,
      selected: nil,
      supporting_text: nil,
      error: nil,
      size: :md,
      disabled: false,
      input_id: nil
    )
      attributes = attributes&.to_h&.symbolize_keys || {}
      name = name || attributes[:name]
      options = attributes[:options] if options.nil?
      label = attributes[:label] if label.nil?
      aria_label = attributes[:aria_label] if aria_label.nil?
      prompt = attributes[:prompt] if prompt.nil?
      selected = attributes[:selected] if selected.nil?
      supporting_text = attributes[:supporting_text] if supporting_text.nil?
      error = attributes[:error] if error.nil?
      size = attributes[:size] if size == :md && attributes.key?(:size)
      disabled = attributes[:disabled] if disabled == false && attributes.key?(:disabled)
      input_id = attributes[:input_id] if input_id.nil?

      raise ArgumentError, "missing keyword: name" if name.nil?
      raise ArgumentError, "missing keyword: options" if options.nil?

      ensure_accessible_name!(label:, aria_label:, component_name: "Select field")

      @name = name
      @options = options
      @label = label
      @aria_label = aria_label
      @prompt = prompt
      @selected = selected
      @supporting_text = supporting_text
      @error = error
      @size = normalize_option(size, allowed: SIZES, error_prefix: "Unknown select field size")
      @disabled = disabled
      @input_id = input_id.presence || generated_input_id(prefix: "select_field", value: name, fallback: "field")
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
      error.present? ? "select-field-error" : "select-field-supporting-text"
    end
  end
end
