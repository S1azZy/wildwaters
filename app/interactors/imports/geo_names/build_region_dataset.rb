require "set"

module Imports
  module GeoNames
    class BuildRegionDataset < ApplicationInteractor
      option :input

      SUPPORTED_FEATURE_CODES = %w[
        PCLI
        ADM1
        PPLA
        PPLC
      ].freeze

      class ValidationContract < ApplicationContract
        params do
          required(:all_countries_path).filled(:string)
          required(:country_codes).filled(:array)
          optional(:alternate_names_path).maybe(:string)
          optional(:languages).array(:string)
          optional(:feature_codes).array(:string)
        end
      end

      def call
        rows = yield load_rows
        alternate_names = yield load_alternate_names(candidate_ids_for(rows))
        records = sort_records(build_records(rows:, alternate_names:))

        Success(records:)
      end

      private

      def load_rows
        safe_file_read do
          rows = []

          File.foreach(all_countries_path, chomp: true) do |line|
            row = parse_country_row(line)
            rows << row if row
          end

          rows
        end
      end

      def parse_country_row(line)
        return if line.blank?

        columns = line.split("\t", -1)
        return if columns.size < 19

        feature_code = columns[7]
        return unless feature_codes.include?(feature_code)

        country_code = columns[8].to_s.upcase
        return unless country_codes.include?(country_code)

        region_kind = map_region_kind(feature_code)
        return unless region_kind

        {
          external_uid: columns[0].strip,
          name: columns[1].to_s.squish,
          ascii_name: columns[2].to_s.squish.presence,
          latitude: parse_coordinate(columns[4]),
          longitude: parse_coordinate(columns[5]),
          feature_code:,
          region_kind:,
          country_code:,
          admin1_code: columns[10].presence,
          admin2_code: columns[11].presence,
          admin3_code: columns[12].presence,
          admin4_code: columns[13].presence
        }
      end

      def build_records(rows:, alternate_names:)
        country_lookup = build_country_lookup(rows)
        admin_lookup = build_admin_lookup(rows)

        rows.map do |row|
          build_record(
            row:,
            alternate_names:,
            country_lookup:,
            admin_lookup:
          )
        end
      end

      def build_record(row:, alternate_names:, country_lookup:, admin_lookup:)
        {
          record_kind: "region",
          external_uid: row.fetch(:external_uid),
          external_url: "https://www.geonames.org/#{row.fetch(:external_uid)}",
          name: row.fetch(:name),
          ascii_name: row[:ascii_name],
          region_kind: row.fetch(:region_kind),
          country_code: row.fetch(:country_code),
          parent_external_uid: parent_external_uid_for(
            row:,
            country_lookup:,
            admin_lookup:
          ),
          latitude: row[:latitude],
          longitude: row[:longitude],
          alternate_names: alternate_names.fetch(row.fetch(:external_uid), [])
        }
      end

      def sort_records(records)
        remaining_records = records.index_by { |record| record.fetch(:external_uid) }
        sorted_records = []
        seen_external_uids = Set.new

        while remaining_records.any?
          ready_records = remaining_records.values.select do |record|
            record[:parent_external_uid].blank? || seen_external_uids.include?(record[:parent_external_uid])
          end
          ready_records = remaining_records.values.sort_by { |record| record.fetch(:external_uid) } if ready_records.empty?

          ready_records.each do |record|
            sorted_records << record
            seen_external_uids << record.fetch(:external_uid)
            remaining_records.delete(record.fetch(:external_uid))
          end
        end

        sorted_records
      end

      def build_country_lookup(rows)
        rows.each_with_object({}) do |row, memo|
          memo[row.fetch(:country_code)] = row.fetch(:external_uid) if row.fetch(:feature_code) == "PCLI"
        end
      end

      def build_admin_lookup(rows)
        rows.each_with_object({}) do |row, memo|
          key = admin_lookup_key(row)
          memo[key] = row.fetch(:external_uid) if key
        end
      end

      def admin_lookup_key(row)
        case row.fetch(:feature_code)
        when "ADM1"
          [ row.fetch(:country_code), row[:admin1_code] ]
        when "ADM2"
          [ row.fetch(:country_code), row[:admin1_code], row[:admin2_code] ]
        when "ADM3"
          [ row.fetch(:country_code), row[:admin1_code], row[:admin2_code], row[:admin3_code] ]
        when "ADM4"
          [ row.fetch(:country_code), row[:admin1_code], row[:admin2_code], row[:admin3_code], row[:admin4_code] ]
        end
      end

      def load_alternate_names(candidate_ids)
        return Success({}) if alternate_names_path.blank?

        safe_file_read do
          Hash.new { |hash, key| hash[key] = [] }.tap do |names|
            File.foreach(alternate_names_path, chomp: true) do |line|
              alternate_name = parse_alternate_name(line:, candidate_ids:)
              names[alternate_name.fetch(:external_uid)] << alternate_name.except(:external_uid) if alternate_name
            end
          end
        end
      end

      def parse_alternate_name(line:, candidate_ids:)
        return if line.blank?

        columns = line.split("\t", -1)
        return if columns.size < 5

        external_uid = columns[1].strip
        return unless candidate_ids.include?(external_uid)

        language_code = columns[2].to_s.strip.downcase
        return unless languages.include?(language_code)

        name = columns[3].to_s.squish
        return if name.blank?

        {
          external_uid:,
          language_code:,
          name:,
          name_role: columns[4] == "1" ? RegionName::NAME_ROLES[:preferred] : RegionName::NAME_ROLES[:alias]
        }
      end

      def candidate_ids_for(rows)
        rows.map { |row| row.fetch(:external_uid) }.to_set
      end

      def safe_file_read(&)
        safe_call(
          Errno::ENOENT,
          on_error: ->(error) { fail_with(code: :region_dataset_build_failed, errors: { base: [ error.message ] }) },
          &
        )
      end

      def parent_external_uid_for(row:, country_lookup:, admin_lookup:)
        case row.fetch(:feature_code)
        when "PCLI"
          nil
        when "ADM1"
          country_lookup[row.fetch(:country_code)]
        when "ADM2"
          admin_lookup[[ row.fetch(:country_code), row[:admin1_code] ]] || country_lookup[row.fetch(:country_code)]
        when "ADM3"
          admin_lookup[[ row.fetch(:country_code), row[:admin1_code], row[:admin2_code] ]] ||
            admin_lookup[[ row.fetch(:country_code), row[:admin1_code] ]] ||
            country_lookup[row.fetch(:country_code)]
        when "ADM4"
          admin_lookup[[ row.fetch(:country_code), row[:admin1_code], row[:admin2_code], row[:admin3_code] ]] ||
            admin_lookup[[ row.fetch(:country_code), row[:admin1_code], row[:admin2_code] ]] ||
            admin_lookup[[ row.fetch(:country_code), row[:admin1_code] ]] ||
            country_lookup[row.fetch(:country_code)]
        else
          admin_lookup[[ row.fetch(:country_code), row[:admin1_code], row[:admin2_code], row[:admin3_code], row[:admin4_code] ]] ||
            admin_lookup[[ row.fetch(:country_code), row[:admin1_code], row[:admin2_code], row[:admin3_code] ]] ||
            admin_lookup[[ row.fetch(:country_code), row[:admin1_code], row[:admin2_code] ]] ||
            admin_lookup[[ row.fetch(:country_code), row[:admin1_code] ]] ||
            country_lookup[row.fetch(:country_code)]
        end
      end

      def map_region_kind(feature_code)
        case feature_code
        when "PCLI"
          "country"
        when "ADM1", "ADM2", "ADM3", "ADM4"
          "area"
        when "PPL", "PPLA", "PPLA2", "PPLA3", "PPLA4", "PPLC"
          "locality"
        when "PRK"
          "park"
        end
      end

      def parse_coordinate(value)
        value.to_s.presence&.to_f
      end

      def all_countries_path
        @all_countries_path ||= resolve_path(input[:all_countries_path])
      end

      def alternate_names_path
        @alternate_names_path ||= resolve_path(input[:alternate_names_path])
      end

      def resolve_path(path)
        return if path.blank?

        pathname = Pathname.new(path)
        pathname = Rails.root.join(pathname) if pathname.relative?
        pathname.to_s
      end

      def country_codes
        @country_codes ||= normalize_string_list(input[:country_codes]).map(&:upcase)
      end

      def languages
        @languages ||= normalize_string_list(input[:languages]).map(&:downcase)
      end

      def feature_codes
        @feature_codes ||= begin
          values = normalize_string_list(input[:feature_codes])
          values.presence || SUPPORTED_FEATURE_CODES
        end
      end

      def normalize_string_list(value)
        Array(value)
          .flat_map { |item| item.to_s.split(",") }
          .map { |item| item.strip }
          .reject(&:blank?)
      end
    end
  end
end
