module Imports
  module GeoNames
    class ImportRunItemJob < ApplicationJob
      queue_as :imports

      def perform(import_run_item_id)
        result = Imports::GeoNames::ProcessRunItem.call(input: { import_run_item_id: })
        return if result.success?

        failure = result.failure

        raise StandardError, "GeoNames import run item failed: #{failure[:code]}"
      end
    end
  end
end
