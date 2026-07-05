module Imports
  module Regions
    class RegionSynchronizer < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:source_record).filled
          required(:parent_region)
          required(:record).filled(:hash)
          required(:create_region).filled
          required(:sync_imported_region).filled
        end
      end

      def call
        existing_link = source_record.region_source_link
        return update_region(existing_link.region) if existing_link

        existing_region = find_existing_region
        return update_region(existing_region) if existing_region

        create_result = create_region.call(input: region_input)
        return Success(create_result.value!.fetch(:region)) if create_result.success?

        create_result
      end

      private

      def source_record
        input.fetch(:source_record)
      end

      def parent_region
        input.fetch(:parent_region)
      end

      def record
        input.fetch(:record)
      end

      def create_region
        input.fetch(:create_region)
      end

      def sync_imported_region
        input.fetch(:sync_imported_region)
      end

      def update_region(region)
        return fail_with(code: :region_not_found) unless region

        sync_result = sync_imported_region.call(input: region_input.merge(region_id: region.id))
        return Success(sync_result.value!.fetch(:region)) if sync_result.success?

        sync_result
      end

      def find_existing_region
        scope = Region.where(
          parent_id: parent_region&.id,
          slug: record.fetch(:name).to_s.parameterize,
          region_kind: record.fetch(:region_kind)
        )

        scope.find_by(country_code: record[:country_code]) || scope.find_by(country_code: nil)
      end

      def region_input
        {
          name: record.fetch(:name),
          region_kind: record.fetch(:region_kind),
          parent_id: parent_region&.id,
          country_code: record[:country_code],
          latitude: record[:latitude],
          longitude: record[:longitude]
        }
      end
    end
  end
end
