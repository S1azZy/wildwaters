module Ui
  class BadgeComponent < ApplicationComponent
    TONES = %i[neutral primary secondary tertiary].freeze
    EMPHASIS = %i[subtle solid].freeze

    attr_reader :tone, :emphasis

    def initialize(tone: :neutral, emphasis: :subtle)
      @tone = normalize_option(tone, allowed: TONES, error_prefix: "Unknown badge tone")
      @emphasis = normalize_option(emphasis, allowed: EMPHASIS, error_prefix: "Unknown badge emphasis")
    end
  end
end
