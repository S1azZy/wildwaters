module Imports
  module GeoNames
    class Settings < ApplicationInteractor
      DEFAULT_INITIATED_BY = "admin/service-actions/geonames-region-import#create"

      option :input

      class ValidationContract < ApplicationContract
        params do
          optional(:source_key).filled(:string)
          optional(:countries).filled(:array)
          optional(:languages).filled(:array)
          optional(:feature_codes).filled(:array)
          optional(:download_alternate_names).filled(:bool)
          optional(:mode).filled(:string)
          optional(:download_dir).filled(:string)
          optional(:initiated_by).filled(:string)
        end
      end

      def call
        Success(defaults.merge(input.compact))
      end

      private

      def defaults
        config = ApplicationConfig.config.imports.geonames

        {
          source_key: config.source_key,
          countries: config.country_codes,
          languages: config.languages,
          feature_codes: config.feature_codes,
          download_alternate_names: config.download_alternate_names,
          mode: config.default_mode,
          download_dir: config.download_dir,
          initiated_by: DEFAULT_INITIATED_BY
        }
      end
    end
  end
end
