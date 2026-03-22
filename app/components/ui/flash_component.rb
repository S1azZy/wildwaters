module Ui
  class FlashComponent < ApplicationComponent
    TYPES = %i[notice alert success info].freeze
    MAPPED_FLASH_TYPES = %i[alert success info].freeze

    attr_reader :type, :title, :message

    def self.collection_attributes(flash)
      flash.filter_map do |type, message|
        next if message.blank?

        {
          type: normalize_flash_type(type),
          message: Array(message).join(", ")
        }
      end
    end

    def self.normalize_flash_type(type)
      candidate = type&.to_sym

      MAPPED_FLASH_TYPES.include?(candidate) ? candidate : :notice
    end

    def initialize(message:, type: :notice, title: nil)
      @type = normalize_option(type, allowed: TYPES, error_prefix: "Unknown flash type")
      @title = title
      @message = message
    end

    def role
      type == :alert ? :alert : :status
    end

    def live_region_priority
      type == :alert ? :assertive : :polite
    end
  end
end
