module Imports
  module GeoNames
    class ProcessRunItem < ApplicationInteractor
      option :input

      option :download_region_dump, default: -> { Imports::GeoNames::DownloadRegionDump }
      option :build_region_dataset, default: -> { Imports::GeoNames::BuildRegionDataset }
      option :apply_dataset, default: -> { Imports::Regions::ApplyDataset }
      option :reconcile_missing_upstream, default: -> { Imports::SourceRecords::ReconcileMissingUpstream }
      option :finalize_run, default: -> { Imports::GeoNames::FinalizeRun }

      class ValidationContract < ApplicationContract
        params do
          required(:import_run_item_id).filled(:integer)
        end
      end

      def call
        item = yield find_item
        return Success(item:, skipped: true) if item.status_succeeded?

        yield process_item(item)

        Success(item:, skipped: false)
      end

      private

      def find_item
        item = Imports::RunItem.includes(import_run: :import_source).find_by(id: input[:import_run_item_id])
        return Success(item) if item

        fail_with(code: :run_item_not_found, errors: { import_run_item_id: [ "not found" ] })
      end

      def process_item(item)
        result = import_item(item)
        yield finish_item(item:, result:)
        yield finalize_terminal_item(item)

        Success()
      end

      def import_item(item)
        yield claim_item(item)
        downloaded_paths = yield download_paths(item)
        records = yield build_records(item:, downloaded_paths:)
        apply_stats = yield apply_records(item:, records:)
        reconciliation_stats = yield reconcile_missing_records(item:, records:)

        Success(
          artifact_paths: downloaded_paths,
          stats: apply_stats.merge(reconciliation_stats)
        )
      end

      def claim_item(item)
        safe_call do
          item.with_lock do
            item.update!(
              status: Imports::RunItem::STATUSES[:running],
              started_at: Time.current,
              finished_at: nil,
              error_class: nil,
              error_message: nil,
              attempts_count: item.attempts_count + 1
            )
          end
        end
      end

      def download_paths(item)
        download_region_dump.call(
          input: {
            country_code: country_code_for(item),
            destination_dir: artifact_dir_for(item),
            include_alternate_names: item.params.fetch("download_alternate_names", true)
          }
        )
      end

      def build_records(item:, downloaded_paths:)
        result = build_region_dataset.call(
          input: dataset_input(item:, downloaded_paths:)
        )

        return result if result.failure?

        Success(result.value!.fetch(:records))
      end

      def apply_records(item:, records:)
        result = apply_dataset.call(
          input: {
            import_run_id: item.import_run_id,
            records:
          }
        )

        return result if result.failure?

        Success(result.value!.fetch(:stats))
      end

      def reconcile_missing_records(item:, records:)
        result = reconcile_missing_upstream.call(
          input: {
            import_run_id: item.import_run_id,
            records:,
            country_code: country_code_for(item)
          }
        )

        return result if result.failure?

        Success(result.value!.fetch(:stats))
      end

      def finish_item(item:, result:)
        if result.failure?
          fail_item(item:, error: result.failure)
        else
          complete_item(
            item:,
            artifact_paths: result.value!.fetch(:artifact_paths),
            stats: result.value!.fetch(:stats)
          )
        end
      end

      def dataset_input(item:, downloaded_paths:)
        {
          country_codes: [ country_code_for(item) ],
          languages: item.params.fetch("languages", []),
          feature_codes: item.params.fetch("feature_codes", []),
          all_countries_path: downloaded_paths.fetch(:all_countries_path),
          alternate_names_path: downloaded_paths[:alternate_names_path]
        }
      end

      def artifact_dir_for(item)
        Rails.root.join(
          item.params.fetch("download_dir", "tmp/imports/geonames"),
          item.import_run_id.to_s,
          country_code_for(item)
        ).to_s
      end

      def country_code_for(item)
        item.params.fetch("country_code", item.item_key).to_s.upcase
      end

      def complete_item(item:, artifact_paths:, stats:)
        safe_call do
          item.update!(
            status: Imports::RunItem::STATUSES[:succeeded],
            finished_at: Time.current,
            artifact_paths: artifact_paths.stringify_keys,
            stats:,
            error_class: nil,
            error_message: nil
          )
        end
      end

      def fail_item(item:, error:)
        safe_call do
          item.update!(
            status: Imports::RunItem::STATUSES[:failed],
            finished_at: Time.current,
            error_class: error_class_for(error),
            error_message: error_message_for(error)
          )
        end
      end

      def finalize_terminal_item(item)
        item.reload
        return Success() unless terminal_item?(item)

        finalize_run.call(input: { import_run_id: item.import_run_id })
      end

      def terminal_item?(item)
        item.status.in?(terminal_statuses)
      end

      def terminal_statuses
        [
          Imports::RunItem::STATUSES[:succeeded],
          Imports::RunItem::STATUSES[:failed],
          Imports::RunItem::STATUSES[:cancelled]
        ]
      end

      def error_class_for(error)
        error.respond_to?(:fetch) ? error.fetch(:code).to_s : error.class.name
      end

      def error_message_for(error)
        error.respond_to?(:fetch) ? error.fetch(:errors, {}).to_json : error.message
      end
    end
  end
end
