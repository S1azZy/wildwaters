module Imports
  module Regions
    class RegionNameSynchronizer < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:region).filled
          required(:source_record).filled
          required(:record).filled(:hash)
        end
      end

      def call
        yield upsert_region_name(
          name: record.fetch(:name),
          language_code: nil,
          name_role: RegionName::NAME_ROLES[:primary],
          preferred: true
        )

        if record[:ascii_name].present?
          yield upsert_region_name(
            name: record[:ascii_name],
            language_code: "en",
            name_role: RegionName::NAME_ROLES[:ascii],
            preferred: false
          )
        end

        Array(record[:alternate_names]).each do |alternate_name|
          yield upsert_region_name(
            name: alternate_name.fetch(:name),
            language_code: alternate_name[:language_code],
            name_role: alternate_name[:name_role],
            preferred: alternate_name[:name_role] == RegionName::NAME_ROLES[:preferred]
          )
        end

        Success()
      end

      private

      def region
        input.fetch(:region)
      end

      def source_record
        input.fetch(:source_record)
      end

      def record
        input.fetch(:record)
      end

      def upsert_region_name(name:, language_code:, name_role:, preferred:)
        normalized_name = RegionName.normalize_name(name)
        region_name = RegionName.find_or_initialize_by(
          region:,
          language_code: language_code.presence,
          normalized_name:,
          name_role:
        )
        region_name.assign_attributes(
          import_source_record: source_record,
          name:,
          preferred:,
          searchable: true
        )

        return Success(region_name) if region_name.save

        fail_with(code: :validation_error, errors: region_name.errors.to_hash)
      end
    end
  end
end
