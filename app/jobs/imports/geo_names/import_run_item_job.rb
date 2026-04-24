module Imports
  module GeoNames
    class ImportRunItemJob < ApplicationJob
      queue_as :default

      def perform(import_run_item_id)
        item = Imports::RunItem.includes(import_run: :import_source).find(import_run_item_id)
        return if item.status_succeeded?

        claim_item!(item)
        downloaded_paths = download_paths_for(item)
        records = build_records(item:, downloaded_paths:)
        result = Imports::Regions::ImportDataset.call(
          input: {
            source_key: item.import_run.import_source.key,
            mode: item.import_run.mode,
            initiated_by: "import_run_item:#{item.id}",
            records:,
            import_run_id: item.import_run_id,
            reconciliation_country_code: item.country_code
          }
        )

        if result.failure?
          fail_item!(item, error: result.failure)
        else
          complete_item!(item, artifact_paths: downloaded_paths, stats: result.value!.fetch(:stats))
        end
      rescue StandardError => error
        fail_item!(item, error:) if item
        raise
      ensure
        Imports::GeoNames::FinalizeRun.call(input: { import_run_id: item.import_run_id }) if item&.reload&.status.in?(terminal_statuses)
      end

      private

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
        Imports::GeoNames::RegionDumpDownloader.call(
          country_codes: [ item.country_code ],
          destination_dir: artifact_dir_for(item),
          include_alternate_names: item.params.fetch("download_alternate_names", true)
        )
      end

      def build_records(item:, downloaded_paths:)
        Imports::GeoNames::RegionDumpDatasetBuilder.call(
          config: item.params.merge(
            "country_codes" => [ item.country_code ],
            "all_countries_path" => downloaded_paths.fetch(:all_countries_path),
            "alternate_names_path" => downloaded_paths[:alternate_names_path]
          )
        )
      end

      def artifact_dir_for(item)
        Rails.root.join(
          item.params.fetch("download_dir", "tmp/imports/geonames"),
          item.import_run_id.to_s,
          item.country_code
        ).to_s
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

      def error_class_for(error)
        error.respond_to?(:fetch) ? error.fetch(:code).to_s : error.class.name
      end

      def error_message_for(error)
        error.respond_to?(:fetch) ? error.fetch(:errors, {}).to_json : error.message
      end

      def terminal_statuses
        [
          Imports::RunItem::STATUSES[:succeeded],
          Imports::RunItem::STATUSES[:failed],
          Imports::RunItem::STATUSES[:cancelled]
        ]
      end
    end
  end
end
