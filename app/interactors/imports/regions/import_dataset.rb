require Rails.root.join("app/lib/imports/geo_names/region_record_connector")
require "set"

module Imports
  module Regions
    class ImportDataset < ApplicationInteractor
      option :input
      option :apply_source_record, default: -> { Imports::Regions::ApplySourceRecord }
      option :region_record_connector, default: -> { Imports::GeoNames::RegionRecordConnector }

      class ValidationContract < ApplicationContract
        params do
          required(:import_run_id).filled(:integer)
          required(:records).filled(:array)
          optional(:reconciliation_country_code).filled(:string)
        end
      end

      def call
        run = yield find_run
        source = yield source_for(run)
        records = yield normalize_records(source)
        stats = stats_for(records)

        yield apply_records(source:, run:, records:, stats:)
        yield reconcile_missing_upstream_records(source:, run:, records:, stats:)

        Success(run:, stats:)
      end

      private

      def find_run
        run = Imports::Run.includes(:import_source).find_by(id: input[:import_run_id])
        return Success(run) if run

        fail_with(code: :run_not_found, errors: { import_run_id: [ "not found" ] })
      end

      def source_for(run)
        source = run.import_source
        return Success(source) if source.enabled?

        fail_with(code: :source_disabled, errors: { import_source: [ "is disabled" ] })
      end

      def normalize_records(source)
        if source.key == "geonames_regions"
          return Success(region_record_connector.call(records: input[:records])) if input[:records].present?
        end

        fail_with(code: :unsupported_source, errors: { import_source: [ "not supported" ] })
      end

      def stats_for(records)
        {
          "processed_count" => 0,
          "record_count" => records.size,
          "created_region_count" => 0,
          "missing_upstream_count" => 0
        }
      end

      def apply_records(source:, run:, records:, stats:)
        records.each do |record|
          result = apply_source_record.call(input: { source:, run:, record: })
          return result if result.failure?

          stats["processed_count"] += 1
          stats["created_region_count"] += 1 if result.value!.fetch(:created_region)
        end

        Success()
      end

      def reconcile_missing_upstream_records(source:, run:, records:, stats:)
        return Success() unless reconcile_missing_upstream?(run)

        seen_external_uids_by_kind = records.each_with_object(Hash.new { |hash, key| hash[key] = Set.new }) do |record, memo|
          memo[record.fetch(:record_kind)] << record.fetch(:external_uid)
        end

        missing_upstream_count = 0

        source_records_for_reconciliation(source).find_each do |source_record|
          next if seen_external_uids_by_kind.fetch(source_record.record_kind, Set.new).include?(source_record.external_uid)

          source_record.update!(
            status: Imports::SourceRecord::STATUSES[:missing_upstream],
            last_import_run: run
          )
          missing_upstream_count += 1
        end

        stats["missing_upstream_count"] = missing_upstream_count

        Success()
      end

      def reconcile_missing_upstream?(run)
        run.mode.in?([ Imports::Run::MODES[:full], Imports::Run::MODES[:replay] ])
      end

      def source_records_for_reconciliation(source)
        return source.source_records unless input[:reconciliation_country_code].present?

        source.source_records.where(
          "normalized_payload ->> 'country_code' = ?",
          input[:reconciliation_country_code].to_s.upcase
        )
      end
    end
  end
end
