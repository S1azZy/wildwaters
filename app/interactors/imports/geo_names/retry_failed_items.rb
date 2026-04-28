module Imports
  module GeoNames
    class RetryFailedItems < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:import_run_id).filled(:integer)
        end
      end

      def call
        run = yield find_run
        failed_items = yield requeue_failed_items(run)
        yield enqueue_items(failed_items)

        Success(run:, items: failed_items)
      end

      private

      def find_run
        run = Imports::Run.includes(:items).find_by(id: input[:import_run_id])
        return Success(run) if run

        fail_with(code: :run_not_found, errors: { import_run_id: [ "not found" ] })
      end

      def requeue_failed_items(run)
        failed_items = []

        run.with_lock do
          failed_items = run.items.status_failed.to_a
          failed_items.each { |item| requeue_item!(item) }
          reopen_run!(run)
        end

        Success(failed_items)
      end

      def enqueue_items(items)
        items.each { |item| Imports::GeoNames::ImportRunItemJob.perform_later(item.id) }

        Success()
      end

      def requeue_item!(item)
        item.update!(
          status: Imports::RunItem::STATUSES[:queued],
          started_at: nil,
          finished_at: nil,
          error_class: nil,
          error_message: nil
        )
      end

      def reopen_run!(run)
        run.update!(
          status: Imports::Run::STATUSES[:running],
          finished_at: nil,
          error_class: nil,
          error_message: nil
        )
      end
    end
  end
end
