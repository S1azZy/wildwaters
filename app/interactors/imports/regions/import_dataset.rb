require Rails.root.join("app/lib/imports/geonames/region_dump_dataset_builder")
require Rails.root.join("app/lib/imports/geonames/region_record_connector")
require "set"

module Imports
  module Regions
    class ImportDataset < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:source_key).filled(:string)
          required(:mode).filled(:string)
          required(:initiated_by).filled(:string)
          optional(:records).maybe(:array)
        end
      end

      def call
        source = yield find_source
        records = yield normalize_records(source)
        run = yield create_run(source:, record_count: records.size)
        stats = {
          "processed_count" => 0,
          "record_count" => records.size,
          "created_region_count" => 0,
          "missing_upstream_count" => 0
        }

        records.each do |record|
          apply_result = Imports::Regions::ApplySourceRecord.call(input: { source:, run:, record: })
          return fail_run(run:, error: apply_result.failure, stats:) if apply_result.failure?

          stats["processed_count"] += 1
          stats["created_region_count"] += 1 if apply_result.value!.fetch(:created_region)
        end

        reconcile_result = reconcile_missing_upstream_records(source:, run:, records:, stats:)
        return fail_run(run:, error: reconcile_result.failure, stats:) if reconcile_result.failure?

        complete_run(source:, run:, stats:)
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      private

      def find_source
        source = Imports::Source.find_by(key: input[:source_key], target_kind: "region")
        return fail_with(code: :source_not_found, errors: { source_key: [ "not found" ] }) unless source
        return Success(source) if source.enabled?

        fail_with(code: :source_disabled, errors: { source_key: [ "is disabled" ] })
      end

      def normalize_records(source)
        if source.key == "geonames_regions"
          return Success(Imports::GeoNames::RegionRecordConnector.call(records: input[:records])) if input[:records].present?
          return load_geonames_dump_records(source) if source.fetch_mode_dump?
        end

        fail_with(code: :unsupported_source, errors: { source_key: [ "not supported" ] })
      end

      def load_geonames_dump_records(source)
        records = Imports::GeoNames::RegionDumpDatasetBuilder.call(config: source.config)

        Success(Imports::GeoNames::RegionRecordConnector.call(records: records))
      rescue ArgumentError, Errno::ENOENT => error
        fail_with(code: :invalid_source_config, errors: { config: [ error.message ] })
      end

      def create_run(source:, record_count:)
        run = source.runs.create!(
          mode: input[:mode],
          status: Imports::Run::STATUSES[:running],
          started_at: Time.current,
          initiated_by: input[:initiated_by],
          stats: { "record_count" => record_count }
        )

        Success(run)
      rescue ActiveRecord::RecordNotUnique
        fail_with(code: :run_already_active, errors: { source_key: [ "already has an active run" ] })
      end

      def complete_run(source:, run:, stats:)
        now = Time.current

        run.update!(
          status: Imports::Run::STATUSES[:succeeded],
          finished_at: now,
          stats:
        )
        source.update!(last_successful_run_at: now)

        Success(run:)
      end

      def fail_run(run:, error:, stats:)
        run.update!(
          status: Imports::Run::STATUSES[:failed],
          finished_at: Time.current,
          error_class: error[:code].to_s,
          error_message: error[:errors].presence&.to_json,
          stats:
        )

        Failure(error)
      end

      def reconcile_missing_upstream_records(source:, run:, records:, stats:)
        return Success() unless reconcile_missing_upstream?

        seen_external_uids_by_kind = records.each_with_object(Hash.new { |hash, key| hash[key] = Set.new }) do |record, memo|
          memo[record.fetch(:record_kind)] << record.fetch(:external_uid)
        end

        missing_upstream_count = 0

        source.source_records.find_each do |source_record|
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

      def reconcile_missing_upstream?
        input[:mode].in?([ Imports::Run::MODES[:full], Imports::Run::MODES[:replay] ])
      end
    end
  end
end
