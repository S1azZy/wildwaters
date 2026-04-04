module Imports
  class RunSourceJob < ApplicationJob
    queue_as :default

    def perform(source_key:, mode:, initiated_by:, records: nil)
      result = Imports::Regions::ImportDataset.call(
        input: {
          source_key:,
          mode:,
          initiated_by:,
          records:
        }
      )

      return if result.failure? == false

      failure = result.failure

      raise StandardError, "Import failed for #{source_key}: #{failure[:code]}"
    end
  end
end
