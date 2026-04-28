module Imports
  class RunSourceJob < ApplicationJob
    queue_as :imports

    def perform(source_key:, mode:, initiated_by:, records: nil)
      result = Imports::Regions::ImportDataset.call(
        input: {
          source_key:,
          mode:,
          initiated_by:,
          records:
        }
      )

      return if result.success?

      failure = result.failure

      raise StandardError, "Import failed for #{source_key}: #{failure[:code]}"
    end
  end
end
