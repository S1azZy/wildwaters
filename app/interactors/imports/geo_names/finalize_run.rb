module Imports
  module GeoNames
    class FinalizeRun < ApplicationInteractor
      option :input

      def call
        run = Imports::Run.find(input.fetch(:import_run_id))

        run.with_lock do
          run.items.reload
          return Success(run:) if run.items.any? { |item| item.status.in?(active_item_statuses) }

          stats = aggregate_stats(run.items)
          status = run.items.any?(&:status_failed?) ? Imports::Run::STATUSES[:partially_failed] : Imports::Run::STATUSES[:succeeded]
          now = Time.current

          run.update!(
            status:,
            finished_at: now,
            stats:
          )
          run.import_source.update!(last_successful_run_at: now) if status == Imports::Run::STATUSES[:succeeded]
        end

        Success(run:)
      end

      private

      def active_item_statuses
        [ Imports::RunItem::STATUSES[:queued], Imports::RunItem::STATUSES[:running] ]
      end

      def aggregate_stats(items)
        {
          "total_item_count" => items.size,
          "succeeded_item_count" => items.count(&:status_succeeded?),
          "failed_item_count" => items.count(&:status_failed?),
          "processed_count" => sum_item_stat(items, "processed_count"),
          "created_region_count" => sum_item_stat(items, "created_region_count"),
          "missing_upstream_count" => sum_item_stat(items, "missing_upstream_count")
        }
      end

      def sum_item_stat(items, key)
        items.sum { |item| item.stats.fetch(key, 0).to_i }
      end
    end
  end
end
