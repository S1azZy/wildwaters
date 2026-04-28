require "set"

module Imports
  module SourceRecords
    class ReconcileMissingUpstream < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:import_run_id).filled(:integer)
          required(:records).filled(:array)
          required(:country_code).filled(:string)
        end
      end

      def call
        run = yield find_run
        return Success(stats: stats_for(0)) unless reconcile_missing_upstream?(run)

        missing_upstream_count = yield mark_missing_records(run)

        Success(stats: stats_for(missing_upstream_count))
      end

      private

      def find_run
        run = Imports::Run.includes(:import_source).find_by(id: input[:import_run_id])
        return Success(run) if run

        fail_with(code: :run_not_found, errors: { import_run_id: [ "not found" ] })
      end

      def reconcile_missing_upstream?(run)
        run.mode.in?([ Imports::Run::MODES[:full], Imports::Run::MODES[:replay] ])
      end

      def mark_missing_records(run)
        missing_upstream_count = 0

        source_records_for_reconciliation(run.import_source).find_each do |source_record|
          next if seen_external_uids_by_kind.fetch(source_record.record_kind, Set.new).include?(source_record.external_uid)

          source_record.update!(
            status: Imports::SourceRecord::STATUSES[:missing_upstream],
            last_import_run: run
          )
          missing_upstream_count += 1
        end

        Success(missing_upstream_count)
      end

      def source_records_for_reconciliation(source)
        source.source_records.where(
          "normalized_payload ->> 'country_code' = ?",
          input.fetch(:country_code).upcase
        )
      end

      def seen_external_uids_by_kind
        @seen_external_uids_by_kind ||= input.fetch(:records).each_with_object(Hash.new { |hash, key| hash[key] = Set.new }) do |record, memo|
          memo[record.fetch(:record_kind)] << record.fetch(:external_uid)
        end
      end

      def stats_for(missing_upstream_count)
        { "missing_upstream_count" => missing_upstream_count }
      end
    end
  end
end
