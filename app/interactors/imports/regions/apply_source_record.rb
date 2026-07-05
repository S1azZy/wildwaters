module Imports
  module Regions
    class ApplySourceRecord < ApplicationInteractor
      option :input
      option :source_record_persister, default: -> { Imports::Regions::SourceRecordPersister }
      option :parent_region_resolver, default: -> { Imports::Regions::ParentRegionResolver }
      option :region_synchronizer, default: -> { Imports::Regions::RegionSynchronizer }
      option :source_link_refresher, default: -> { Imports::Regions::SourceLinkRefresher }
      option :region_name_synchronizer, default: -> { Imports::Regions::RegionNameSynchronizer }
      option :source_record_matcher, default: -> { Imports::Regions::SourceRecordMatcher }
      option :create_region, default: -> { ::Regions::CreateRegion }
      option :sync_imported_region, default: -> { ::Regions::SyncImportedRegion }

      class ValidationContract < ApplicationContract
        params do
          required(:source).filled
          required(:run).filled
          required(:record).filled(:hash)
        end
      end

      def call
        in_transaction do
          source = input.fetch(:source)
          run = input.fetch(:run)
          record = input.fetch(:record)

          source_record = yield source_record_persister.call(input: { source:, run:, record: })
          parent_region = yield parent_region_resolver.call(input: { source:, record: })
          region = yield region_synchronizer.call(
            input: {
              source_record:,
              parent_region:,
              record:,
              create_region:,
              sync_imported_region:
            }
          )
          yield source_link_refresher.call(input: { source:, source_record:, region:, record: })
          yield region_name_synchronizer.call(input: { region:, source_record:, record: })
          yield source_record_matcher.call(input: { source_record:, run:, record: })

          Success(created_region: region.previous_changes.key?("id"))
        end
      rescue KeyError => error
        fail_with(code: :validation_error, errors: { input: [ error.message ] })
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end
end
