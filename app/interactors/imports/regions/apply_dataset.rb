module Imports
  module Regions
    class ApplyDataset < ApplicationInteractor
      option :input
      option :apply_source_record, default: -> { Imports::Regions::ApplySourceRecord }

      class ValidationContract < ApplicationContract
        params do
          required(:import_run_id).filled(:integer)
          required(:records).filled(:array)
        end
      end

      def call
        run = yield find_run
        source = yield source_for(run)
        records = input.fetch(:records)
        stats = stats_for(records)

        yield apply_records(source:, run:, records:, stats:)

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

      def stats_for(records)
        {
          "processed_count" => 0,
          "record_count" => records.size,
          "created_region_count" => 0
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
    end
  end
end
