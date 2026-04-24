module Imports
  module GeoNames
    class RetryFailedItems < ApplicationInteractor
      option :input

      def call
        run = Imports::Run.includes(:items).find(input.fetch(:import_run_id))
        failed_items = []

        run.with_lock do
          failed_items = run.items.status_failed.to_a
          failed_items.each do |item|
            item.update!(
              status: Imports::RunItem::STATUSES[:queued],
              started_at: nil,
              finished_at: nil,
              error_class: nil,
              error_message: nil
            )
          end
          run.update!(
            status: Imports::Run::STATUSES[:running],
            finished_at: nil,
            error_class: nil,
            error_message: nil
          )
        end

        failed_items.each do |item|
          Imports::GeoNames::ImportRunItemJob.set(queue: item.params.fetch("queue", "default")).perform_later(item.id)
        end

        Success(run:, items: failed_items)
      end
    end
  end
end
