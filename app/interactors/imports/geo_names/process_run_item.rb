module Imports
  module GeoNames
    class ProcessRunItem < ApplicationInteractor
      option :input

      option :region_dump_downloader, default: -> { Imports::GeoNames::RegionDumpDownloader }
      option :region_dump_dataset_builder, default: -> { Imports::GeoNames::RegionDumpDatasetBuilder }
      option :import_dataset, default: -> { Imports::Regions::ImportDataset }
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
        finalize_result = finalize_terminal_item(item)

        return finalize_result if finalize_result.failure?

        result
      end

      def import_item(item)
        claim_item!(item)
        downloaded_paths = download_paths_for(item)
        records = build_records(item:, downloaded_paths:)
        import_records(item:, records:, downloaded_paths:)
      rescue StandardError => error
        fail_item!(item, error:)
        fail_with(code: :run_item_import_failed, errors: { base: [ error.message ] })
      end

      def claim_item!(item)
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

      def download_paths_for(item)
        region_dump_downloader.call(
          country_codes: [ country_code_for(item) ],
          destination_dir: artifact_dir_for(item),
          include_alternate_names: item.params.fetch("download_alternate_names", true)
        )
      end

      def build_records(item:, downloaded_paths:)
        region_dump_dataset_builder.call(
          config: item.params.merge(
            "country_codes" => [ country_code_for(item) ],
            "all_countries_path" => downloaded_paths.fetch(:all_countries_path),
            "alternate_names_path" => downloaded_paths[:alternate_names_path]
          )
        )
      end

      def import_records(item:, records:, downloaded_paths:)
        result = import_dataset.call(input: import_input(item:, records:))

        if result.failure?
          fail_item!(item, error: result.failure)
        else
          complete_item!(item, artifact_paths: downloaded_paths, stats: result.value!.fetch(:stats))
        end

        Success()
      end

      def import_input(item:, records:)
        {
          import_run_id: item.import_run_id,
          records:,
          reconciliation_country_code: country_code_for(item)
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

      def complete_item!(item, artifact_paths:, stats:)
        item.update!(
          status: Imports::RunItem::STATUSES[:succeeded],
          finished_at: Time.current,
          artifact_paths: artifact_paths.stringify_keys,
          stats:,
          error_class: nil,
          error_message: nil
        )
      end

      def fail_item!(item, error:)
        item.update!(
          status: Imports::RunItem::STATUSES[:failed],
          finished_at: Time.current,
          error_class: error_class_for(error),
          error_message: error_message_for(error)
        )
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
