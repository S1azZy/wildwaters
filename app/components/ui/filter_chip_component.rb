module Ui
  class FilterChipComponent < ApplicationComponent
    attr_reader :selected, :disabled

    def initialize(selected: false, disabled: false)
      @selected = selected
      @disabled = disabled
    end

    def state
      return :selected if selected
      return :disabled if disabled

      :default
    end
  end
end
