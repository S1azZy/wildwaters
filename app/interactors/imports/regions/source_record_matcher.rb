module Imports
  module Regions
    class SourceRecordMatcher < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:source_record).filled
          required(:run).filled
          required(:record).filled(:hash)
        end
      end

      def call
        source_record.assign_attributes(
          status: Imports::SourceRecord::STATUSES[:matched],
          normalized_payload: RecordPayload.normalized(record),
          last_import_run: run
        )

        return Success(source_record) if source_record.save

        fail_with(code: :validation_error, errors: source_record.errors.to_hash)
      end

      private

      def source_record
        input.fetch(:source_record)
      end

      def run
        input.fetch(:run)
      end

      def record
        input.fetch(:record)
      end
    end
  end
end
