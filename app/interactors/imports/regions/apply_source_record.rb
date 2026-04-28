require "digest"
require "json"

module Imports
  module Regions
    class ApplySourceRecord < ApplicationInteractor
      option :input
      option :create_region, default: -> { ::Regions::CreateRegion }
      option :sync_imported_region, default: -> { ::Regions::SyncImportedRegion }

      def call
        in_transaction do
          source = input.fetch(:source)
          run = input.fetch(:run)
          record = input.fetch(:record)

          source_record = yield upsert_source_record(source:, run:, record:)
          parent_region = yield find_parent_region(source:, record:)
          region = yield find_or_create_region(source:, source_record:, parent_region:, record:)
          yield refresh_link(source:, source_record:, region:, record:)
          yield sync_region_names(region:, source_record:, record:)
          yield mark_source_record_matched(source_record:, run:, record:)

          Success(created_region: region.previous_changes.key?("id"))
        end
      rescue KeyError => error
        fail_with(code: :validation_error, errors: { input: [ error.message ] })
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      private

      def upsert_source_record(source:, run:, record:)
        now = Time.current
        raw_payload = record.deep_stringify_keys
        normalized_payload = normalized_payload_for(record)
        checksum = checksum_for(
          {
            "raw_payload" => raw_payload,
            "normalized_payload" => normalized_payload
          }
        )

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

        yield capture_snapshot(source_record:, run:, raw_payload:) if payload_changed

        Success(source_record)
      end

      def find_parent_region(source:, record:)
        parent_external_uid = record[:parent_external_uid]
        return Success(nil) if parent_external_uid.blank?

        parent_source_record = source.source_records.find_by(
          record_kind: record.fetch(:record_kind),
          external_uid: parent_external_uid
        )
        parent_region = parent_source_record&.region_source_link&.region

        return Success(parent_region) if parent_region

        fail_with(code: :parent_not_found, errors: { parent_external_uid: [ "not found" ] })
      end

      def find_or_create_region(source:, source_record:, parent_region:, record:)
        existing_link = source_record.region_source_link
        return update_region(existing_link.region, parent_region:, record:) if existing_link

        existing_region = find_existing_region(parent_region:, record:)

        return update_region(existing_region, parent_region:, record:) if existing_region

        create_result = create_region.call(
          input: {
            name: record.fetch(:name),
            region_kind: record.fetch(:region_kind),
            parent_id: parent_region&.id,
            country_code: record[:country_code],
            latitude: record[:latitude],
            longitude: record[:longitude]
          }
        )

        return Success(create_result.value!.fetch(:region)) if create_result.success?

        create_result
      end

      def update_region(region, parent_region:, record:)
        return fail_with(code: :region_not_found) unless region

        sync_result = sync_imported_region.call(
          input: {
            region_id: region.id,
            parent_id: parent_region&.id,
            name: record.fetch(:name),
            region_kind: record.fetch(:region_kind),
            country_code: record[:country_code],
            latitude: record[:latitude],
            longitude: record[:longitude]
          }
        )
        return Success(sync_result.value!.fetch(:region)) if sync_result.success?

        sync_result
      end

      def find_existing_region(parent_region:, record:)
        scope = Region.where(
          parent_id: parent_region&.id,
          slug: record.fetch(:name).to_s.parameterize,
          region_kind: record.fetch(:region_kind)
        )

        exact_match = scope.find_by(country_code: record[:country_code])
        return exact_match if exact_match

        scope.find_by(country_code: nil)
      end

      def refresh_link(source:, source_record:, region:, record:)
        link = source_record.region_source_link || source_record.build_region_source_link
        link.assign_attributes(
          region:,
          match_strategy: link.match_strategy || match_strategy_for(region:, record:),
          confidence: 1.0,
          primary_identity: source.source_role_canonical_identity?,
          matched_at: Time.current
        )

        return Success(link) if link.save

        fail_with(code: :validation_error, errors: link.errors.to_hash)
      end

      def sync_region_names(region:, source_record:, record:)
        upsert_region_name(
          region:,
          source_record:,
          name: record.fetch(:name),
          language_code: nil,
          name_role: RegionName::NAME_ROLES[:primary],
          preferred: true
        )

        if record[:ascii_name].present?
          upsert_region_name(
            region:,
            source_record:,
            name: record[:ascii_name],
            language_code: "en",
            name_role: RegionName::NAME_ROLES[:ascii],
            preferred: false
          )
        end

        Array(record[:alternate_names]).each do |alternate_name|
          upsert_region_name(
            region:,
            source_record:,
            name: alternate_name.fetch(:name),
            language_code: alternate_name[:language_code],
            name_role: alternate_name[:name_role],
            preferred: alternate_name[:name_role] == RegionName::NAME_ROLES[:preferred]
          )
        end

        Success()
      end

      def upsert_region_name(region:, source_record:, name:, language_code:, name_role:, preferred:)
        normalized_name = RegionName.normalize_name(name)
        region_name = RegionName.find_or_initialize_by(
          region:,
          language_code: language_code.presence,
          normalized_name:,
          name_role:
        )
        region_name.assign_attributes(
          import_source_record: source_record,
          name:,
          preferred:,
          searchable: true
        )
        region_name.save!
      end

      def mark_source_record_matched(source_record:, run:, record:)
        source_record.assign_attributes(
          status: Imports::SourceRecord::STATUSES[:matched],
          normalized_payload: normalized_payload_for(record),
          last_import_run: run
        )

        return Success(source_record) if source_record.save

        fail_with(code: :validation_error, errors: source_record.errors.to_hash)
      end

      def normalized_payload_for(record)
        {
          "name" => record[:name],
          "ascii_name" => record[:ascii_name],
          "region_kind" => record[:region_kind],
          "country_code" => record[:country_code],
          "parent_external_uid" => record[:parent_external_uid],
          "latitude" => record[:latitude],
          "longitude" => record[:longitude],
          "alternate_names" => Array(record[:alternate_names]).map(&:deep_stringify_keys)
        }
      end

      def checksum_for(payload)
        Digest::SHA256.hexdigest(JSON.generate(deep_sort_value(payload)))
      end

      def capture_snapshot(source_record:, run:, raw_payload:)
        snapshot = source_record.record_snapshots.new(
          import_run: run,
          checksum: source_record.checksum,
          payload: raw_payload,
          captured_at: Time.current
        )

        return Success(snapshot) if snapshot.save

        fail_with(code: :validation_error, errors: snapshot.errors.to_hash)
      end

      def deep_sort_value(value)
        case value
        when Hash
          value.keys.sort.each_with_object({}) do |key, memo|
            memo[key] = deep_sort_value(value.fetch(key))
          end
        when Array
          value.map { |item| deep_sort_value(item) }
        else
          value
        end
      end

      def match_strategy_for(region:, record:)
        return "existing_source_link" if region.source_links.exists?
        return "structural_match" if Region.exists?(id: region.id)

        record[:parent_external_uid].present? ? "canonical_hierarchy_create" : "canonical_root_create"
      end

      def build_center(record)
        return if record[:latitude].blank? || record[:longitude].blank?

        Region.spatial_factory.point(record[:longitude], record[:latitude])
      end
    end
  end
end
