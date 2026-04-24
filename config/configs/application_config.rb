# frozen_string_literal: true

require_relative "configurable"

class ApplicationConfig
  extend Wildwaters::Configurable

  OptionalPath = Types::String.optional
  OptionalInteger = Types::Params::Integer.optional
  StringBool = Types::Params::Bool
  StorageService = Types::Symbol.constructor { _1.to_s.to_sym }
  CommaSeparatedStrings = Types::Array.of(Types::String).constructor do |input|
    input.to_s.split(",").map(&:strip).reject(&:blank?)
  end
  CountryCodes = CommaSeparatedStrings.constructor { |values| values.map(&:upcase) }
  LanguageCodes = CommaSeparatedStrings.constructor { |values| values.map(&:downcase) }
  FeatureCodes = CommaSeparatedStrings.constructor { |values| values.map(&:upcase) }

  setting :urls do
    setting :host, default: "localhost", constructor: Types::String.constrained(filled: true)
    setting :port, default: nil, constructor: OptionalInteger
    setting :protocol, default: "http", constructor: Types::String.constrained(filled: true)
  end

  setting :storage do
    setting :service, default: :local, constructor: StorageService
  end

  setting :imports do
    setting :geonames do
      setting :source_key, default: "geonames_regions", constructor: Types::String.constrained(filled: true)
      setting :country_codes, constructor: CountryCodes
      setting :languages, default: %w[en ru], constructor: LanguageCodes
      setting :feature_codes, constructor: FeatureCodes
      setting :download_alternate_names, default: true, constructor: StringBool
      setting :download_dir, default: "tmp/imports/geonames/geonames_regions",
        constructor: Types::String.constrained(filled: true)
      setting :initiated_by, default: "manual", constructor: Types::String.constrained(filled: true)
      setting :mode, default: "full", constructor: Types::String.constrained(filled: true)
      setting :all_countries_path, default: nil, constructor: OptionalPath
      setting :alternate_names_path, default: nil, constructor: OptionalPath
    end
  end

  def self.load_from_env!
    configure do |config|
      config.urls.host = ENV.fetch("APP_HOST", default_host)
      config.urls.port = ENV["APP_PORT"]
      config.urls.protocol = ENV.fetch("APP_PROTOCOL", default_protocol)
      config.storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", default_storage_service)

      geonames = config.imports.geonames
      geonames.source_key = env_fetch("GEONAMES_SOURCE_KEY", "SOURCE_KEY", "geonames_regions")
      geonames.country_codes = env_fetch("GEONAMES_COUNTRY_CODES", "COUNTRY_CODES", "")
      geonames.languages = env_fetch("GEONAMES_LANGUAGES", "LANGUAGES", "en,ru")
      geonames.feature_codes = env_fetch("GEONAMES_FEATURE_CODES", "FEATURE_CODES", "PCLI,ADM1,PPLA,PPLC")
      geonames.download_alternate_names = env_fetch(
        "GEONAMES_DOWNLOAD_ALTERNATE_NAMES",
        "DOWNLOAD_ALTERNATE_NAMES",
        true
      )
      geonames.download_dir = env_fetch(
        "GEONAMES_DOWNLOAD_DIR",
        "DOWNLOAD_DIR",
        "tmp/imports/geonames/#{geonames.source_key}"
      )
      geonames.initiated_by = env_fetch("GEONAMES_INITIATED_BY", "INITIATED_BY", "manual")
      geonames.mode = env_fetch("GEONAMES_MODE", "MODE", "full")
      geonames.all_countries_path = env_fetch("GEONAMES_ALL_COUNTRIES_PATH", "ALL_COUNTRIES_PATH", nil)
      geonames.alternate_names_path = env_fetch("GEONAMES_ALTERNATE_NAMES_PATH", "ALTERNATE_NAMES_PATH", nil)
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

  def self.env_fetch(primary_key, fallback_key, default)
    return ENV[primary_key] if ENV.key?(primary_key)
    return ENV[fallback_key] if ENV.key?(fallback_key)

    default
  end
  private_class_method :env_fetch

  def self.default_host
    return "example.com" if rails_env?(:test) || rails_env?(:production)

    "localhost"
  end
  private_class_method :default_host

  def self.default_protocol
    rails_env?(:production) ? "https" : "http"
  end
  private_class_method :default_protocol

  def self.default_storage_service
    rails_env?(:test) ? :test : :local
  end
  private_class_method :default_storage_service

  def self.rails_env?(name)
    defined?(Rails) && Rails.env.public_send("#{name}?")
  end
  private_class_method :rails_env?
end
