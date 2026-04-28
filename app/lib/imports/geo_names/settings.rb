module Imports
  module GeoNames
    class Settings
      class << self
        def from_env(initiated_by:, overrides: {})
          config = ApplicationConfig.config.imports.geonames
          new(
            source_key: config.source_key,
            countries: countries_from_env(config),
            languages: config.languages,
            feature_codes: config.feature_codes,
            download_alternate_names: config.download_alternate_names,
            mode: config.default_mode,
            download_dir: config.download_dir,
            initiated_by:
          ).merge(overrides)
        end

        private

        def countries_from_env(config)
          raw_value = ENV["GEONAMES_COUNTRY_CODES"].presence || config.country_codes
          normalize_list(raw_value).map(&:upcase)
        end

        def normalize_list(value)
          Array(value)
            .flat_map { |item| item.to_s.split(",") }
            .map(&:strip)
            .reject(&:blank?)
        end
      end

      def initialize(source_key:, countries:, languages:, feature_codes:, download_alternate_names:, mode:, download_dir:, initiated_by:)
        @attributes = {
          source_key:,
          countries: normalize_list(countries).map(&:upcase),
          languages: normalize_list(languages).map(&:downcase),
          feature_codes: normalize_list(feature_codes).map(&:upcase),
          download_alternate_names:,
          mode:,
          download_dir:,
          initiated_by:
        }
      end

      def merge(overrides)
        self.class.new(**attributes.merge(overrides))
      end

      def to_h
        attributes
      end

      private

      attr_reader :attributes

      def normalize_list(value)
        Array(value)
          .flat_map { |item| item.to_s.split(",") }
          .map(&:strip)
          .reject(&:blank?)
          .uniq
      end
    end
  end
end
