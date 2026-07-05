module Imports
  module Regions
    class SourceRecordPersister < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:source).filled
          required(:run).filled
          required(:record).filled(:hash)
        end
      end

      def call
        now = Time.current
        raw_payload = RecordPayload.raw(record)
        normalized_payload = RecordPayload.normalized(record)
        checksum = RecordPayload.checksum(raw_payload:, normalized_payload:)

        source_record = source.source_records.find_or_initialize_by(
          record_kind: record.fetch(:record_kind),
          external_uid: record.fetch(:external_uid)
        )
        payload_changed = source_record.new_record? || source_record.checksum != checksum

        source_record.assign_attributes(
          external_url: record[:external_url],
          status: Imports::SourceRecord::STATUSES[:pending],
          checksum:,
          raw_payload:,
          normalized_payload:,
          last_seen_at: now,
          last_import_run: run
        )
        source_record.first_seen_at ||= now
        source_record.last_changed_at = now if payload_changed

        return fail_with(code: :validation_error, errors: source_record.errors.to_hash) unless source_record.save

        yield capture_snapshot(source_record:, raw_payload:) if payload_changed

        Success(source_record)
      end

      private

      def source
        input.fetch(:source)
      end

      def run
        input.fetch(:run)
      end

      def record
        input.fetch(:record)
      end

      def capture_snapshot(source_record:, raw_payload:)
        snapshot = source_record.record_snapshots.new(
          import_run: run,
          checksum: source_record.checksum,
          payload: raw_payload,
          captured_at: Time.current
        )

        return Success(snapshot) if snapshot.save

        fail_with(code: :validation_error, errors: snapshot.errors.to_hash)
      end
    end
  end
end
