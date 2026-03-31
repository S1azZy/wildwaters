require "set"

module Imports
  module GeoNames
    class RegionDumpDatasetBuilder
      SUPPORTED_FEATURE_CODES = %w[
        PCLI
        ADM1
        ADM2
        ADM3
        ADM4
        PPL
        PPLA
        PPLA2
        PPLA3
        PPLA4
        PPLC
        PRK
      ].freeze

      class << self
        def call(config:)
          new(config:).call
        end
      end

      def initialize(config:)
        @config = config.deep_symbolize_keys
      end

      def call
        validate_config!

        rows = load_rows
        country_lookup = build_country_lookup(rows)
        admin_lookup = build_admin_lookup(rows)
        candidate_ids = rows.map { |row| row.fetch(:external_uid) }.to_set
        alternate_names = load_alternate_names(candidate_ids)

        rows.map do |row|
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
      end

      private

      attr_reader :config

      def validate_config!
        raise ArgumentError, "all_countries_path is required" if all_countries_path.blank?
        raise ArgumentError, "country_codes must be provided explicitly" if country_codes.empty?
      end

      def load_rows
        rows = []

        File.foreach(all_countries_path, chomp: true) do |line|
          next if line.blank?

          columns = line.split("\t", -1)
          next if columns.size < 19

          feature_code = columns[7]
          next unless feature_codes.include?(feature_code)

          country_code = columns[8].to_s.upcase
          next unless country_codes.include?(country_code)

          region_kind = map_region_kind(feature_code)
          next unless region_kind

          rows << {
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

        rows
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
        return {} if alternate_names_path.blank?

        Hash.new { |hash, key| hash[key] = [] }.tap do |names|
          File.foreach(alternate_names_path, chomp: true) do |line|
            next if line.blank?

            columns = line.split("\t", -1)
            next if columns.size < 5

            external_uid = columns[1].strip
            next unless candidate_ids.include?(external_uid)

            language_code = columns[2].to_s.strip.downcase
            next unless languages.include?(language_code)

            name = columns[3].to_s.squish
            next if name.blank?

            names[external_uid] << {
              language_code:,
              name:,
              name_role: columns[4] == "1" ? RegionName::NAME_ROLES[:preferred] : RegionName::NAME_ROLES[:alias]
            }
          end
        end
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
        @all_countries_path ||= resolve_path(config[:all_countries_path])
      end

      def alternate_names_path
        @alternate_names_path ||= resolve_path(config[:alternate_names_path])
      end

      def resolve_path(path)
        return if path.blank?

        pathname = Pathname.new(path)
        pathname = Rails.root.join(pathname) if pathname.relative?
        pathname.to_s
      end

      def country_codes
        @country_codes ||= normalize_string_list(config[:country_codes]).map(&:upcase)
      end

      def languages
        @languages ||= normalize_string_list(config[:languages]).map(&:downcase)
      end

      def feature_codes
        @feature_codes ||= begin
          values = normalize_string_list(config[:feature_codes])
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
