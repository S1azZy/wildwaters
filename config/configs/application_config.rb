# frozen_string_literal: true

require_relative "configurable"

class ApplicationConfig
  extend Wildwaters::Configurable

  OptionalPath = Types::String.optional
  OptionalInteger = Types::Params::Integer.optional
  StringBool = Types::Params::Bool
  StorageService = Types::Symbol.constructor { _1.to_s.to_sym }
  CommaSeparatedStrings = Types::Array.of(Types::String).constructor do |input|
    input.to_s.split(",").map(&:strip).reject(&:empty?)
  end
  CountryCodes = CommaSeparatedStrings.constructor { |values| values.map(&:upcase) }
  LanguageCodes = CommaSeparatedStrings.constructor { |values| values.map(&:downcase) }
  FeatureCodes = CommaSeparatedStrings.constructor { |values| values.map(&:upcase) }

  setting :urls do
    setting :host, constructor: Types::String.constrained(filled: true)
    setting :port, constructor: OptionalInteger
    setting :protocol, constructor: Types::String.constrained(filled: true)
  end

  setting :storage do
    setting :service, constructor: StorageService
  end

  setting :imports do
    setting :geonames do
      setting :source_key, constructor: Types::String.constrained(filled: true)
      setting :country_codes, constructor: CountryCodes
      setting :languages, constructor: LanguageCodes
      setting :feature_codes, constructor: FeatureCodes
      setting :download_alternate_names, constructor: StringBool
      setting :default_mode, constructor: Types::String.constrained(filled: true)
      setting :queue, constructor: Types::String.constrained(filled: true)
      setting :download_dir, constructor: Types::String.constrained(filled: true)
      setting :all_countries_path, constructor: OptionalPath
      setting :alternate_names_path, constructor: OptionalPath
    end
  end
  def self.default_url_options
    options = {
      host: config.urls.host,
      protocol: config.urls.protocol
    }
    options[:port] = config.urls.port if config.urls.port
    options
  end
end
