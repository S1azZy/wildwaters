module Imports
  module GeoNames
    class RegionRecordConnector
      class << self
        def call(records:)
          normalized_records = Array(records).map { |record| normalize_record(record) }

          sort_records(normalized_records)
        end

        private

        def normalize_record(record)
          normalized_record = record.deep_symbolize_keys

          {
            record_kind: normalized_record.fetch(:record_kind).to_s.strip,
            external_uid: normalized_record.fetch(:external_uid).to_s.strip,
            external_url: normalized_record[:external_url].to_s.strip.presence,
            name: normalized_record.fetch(:name).to_s.squish,
            ascii_name: normalized_record[:ascii_name].to_s.squish.presence,
            region_kind: normalized_record.fetch(:region_kind).to_s.strip,
            country_code: normalized_record[:country_code].to_s.strip.upcase.presence,
            parent_external_uid: normalized_record[:parent_external_uid].to_s.strip.presence,
            latitude: normalized_record[:latitude],
            longitude: normalized_record[:longitude],
            alternate_names: normalize_alternate_names(normalized_record[:alternate_names])
          }
        end

        def normalize_alternate_names(alternate_names)
          Array(alternate_names).filter_map do |alternate_name|
            name = alternate_name[:name].to_s.squish.presence
            next unless name

            {
              language_code: alternate_name[:language_code].to_s.strip.downcase.presence,
              name:,
              name_role: alternate_name[:name_role].to_s.strip.presence || RegionName::NAME_ROLES[:alias]
            }
          end
        end

        def sort_records(records)
          remaining_records = records.index_by { |record| record.fetch(:external_uid) }
          sorted_records = []
          seen_external_uids = Set.new

          while remaining_records.any?
            ready_records = remaining_records.values.select do |record|
              record[:parent_external_uid].blank? || seen_external_uids.include?(record[:parent_external_uid])
            end

            ready_records = remaining_records.values.sort_by { |record| record[:external_uid] } if ready_records.empty?

            ready_records.each do |record|
              sorted_records << record
              seen_external_uids << record.fetch(:external_uid)
              remaining_records.delete(record.fetch(:external_uid))
            end
          end

          sorted_records
        end
      end
    end
  end
end
