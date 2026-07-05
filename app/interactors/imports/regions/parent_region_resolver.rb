module Imports
  module Regions
    class ParentRegionResolver < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:source).filled
          required(:record).filled(:hash)
        end
      end

      def call
        parent_external_uid = record[:parent_external_uid]
        return Success(nil) if parent_external_uid.blank?

        parent_source_record = source.source_records.find_by(
          record_kind: record.fetch(:record_kind),
          external_uid: parent_external_uid
        )
        parent_region = parent_source_record&.region_source_link&.region

        return Success(parent_region) if parent_region

        fail_with(code: :parent_not_found, errors: { parent_external_uid: [ "not found" ] })
      end

      private

      def source
        input.fetch(:source)
      end

      def record
        input.fetch(:record)
      end
    end
  end
end
