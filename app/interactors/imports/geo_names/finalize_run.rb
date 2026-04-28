module Imports
  module GeoNames
    class FinalizeRun < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:import_run_id).filled(:integer)
        end
      end

      def call
        run = yield find_run
        run = yield finalize_run(run)

        Success(run:)
      end

      private

      def find_run
        run = Imports::Run.includes(:items, :import_source).find_by(id: input[:import_run_id])
        return Success(run) if run

        fail_with(code: :run_not_found, errors: { import_run_id: [ "not found" ] })
      end

      def finalize_run(run)
        result = nil

        run.with_lock do
          items = run.items.reload
          result = active_items?(items) ? Success(run) : complete_run!(run:, items:)
        end

        result
      end

      def active_items?(items)
        items.any? { |item| item.status.in?(active_item_statuses) }
      end

      def complete_run!(run:, items:)
        safe_call do
          now = Time.current
          status = final_status(items)

          run.update!(
            status:,
            finished_at: now,
            stats: aggregate_stats(items)
          )
          run.import_source.update!(last_successful_run_at: now) if status == Imports::Run::STATUSES[:succeeded]

          run
        end
      end

      def final_status(items)
        return Imports::Run::STATUSES[:partially_failed] if items.any?(&:status_failed?)

        Imports::Run::STATUSES[:succeeded]
      end

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
