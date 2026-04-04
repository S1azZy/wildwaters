require "fileutils"
require "net/http"
require "pathname"
require "stringio"
require "uri"
require "zip"

module Imports
  module GeoNames
    class RegionDumpDownloader
      Error = Class.new(StandardError)

      COUNTRY_DUMP_BASE_URL = "https://download.geonames.org/export/dump".freeze
      ALTERNATE_NAMES_BASE_URL = "https://download.geonames.org/export/dump/alternatenames".freeze
      DEFAULT_OPEN_TIMEOUT = 30
      DEFAULT_READ_TIMEOUT = 300

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(
        country_codes:,
        destination_dir:,
        include_alternate_names: true,
        open_timeout: DEFAULT_OPEN_TIMEOUT,
        read_timeout: DEFAULT_READ_TIMEOUT,
        http_getter: nil
      )
        @country_codes = normalize_country_codes(country_codes)
        @destination_dir = resolve_destination_dir(destination_dir)
        @include_alternate_names = include_alternate_names
        @open_timeout = open_timeout
        @read_timeout = read_timeout
        @http_getter = http_getter || method(:fetch_response)
      end

      def call
        validate_country_codes!
        prepare_destination_dir!

        {
          all_countries_path: write_combined_dump(
            output_path: destination_dir.join("all_countries.txt"),
            base_url: COUNTRY_DUMP_BASE_URL
          ),
          alternate_names_path: alternate_names_path
        }.compact
      end

      private

      attr_reader :country_codes, :destination_dir, :include_alternate_names, :open_timeout, :read_timeout, :http_getter

      def alternate_names_path
        return unless include_alternate_names

        write_combined_dump(
          output_path: destination_dir.join("alternate_names.txt"),
          base_url: ALTERNATE_NAMES_BASE_URL
        )
      end

      def write_combined_dump(output_path:, base_url:)
        File.open(output_path, "wb") do |output_file|
          country_codes.each do |country_code|
            append_entry_to(output_file:, body: fetch_zip_body(base_url:, country_code:), country_code:)
          end
        end

        output_path.to_s
      end

      def fetch_zip_body(base_url:, country_code:)
        uri = URI("#{base_url}/#{country_code}.zip")
        response = http_getter.call(uri, open_timeout:, read_timeout:)

        unless response.is_a?(Net::HTTPSuccess)
          raise Error, "Unable to download GeoNames dump for #{country_code} from #{uri} (HTTP #{response.code})"
        end

        response.body
      rescue Error
        raise
      rescue StandardError => error
        raise Error, "Unable to download GeoNames dump for #{country_code} from #{uri}: #{error.message}"
      end

      def append_entry_to(output_file:, body:, country_code:)
        entry_name = "#{country_code}.txt"
        entry_contents = nil

        Zip::File.open_buffer(StringIO.new(body)) do |zip_file|
          entry = zip_file.find_entry(entry_name)
          raise Error, "Archive for #{country_code} does not contain #{entry_name}" unless entry

          entry_contents = entry.get_input_stream.read
        end

        output_file.write(entry_contents)
        output_file.write("\n") unless entry_contents.end_with?("\n")
      rescue Error
        raise
      rescue Zip::Error => error
        raise Error, "Unable to extract #{entry_name} from downloaded GeoNames archive: #{error.message}"
      end

      def fetch_response(uri, open_timeout:, read_timeout:)
        Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: uri.scheme == "https",
          open_timeout:,
          read_timeout:
        ) do |http|
          request = Net::HTTP::Get.new(uri)
          http.request(request)
        end
      end

      def prepare_destination_dir!
        FileUtils.mkdir_p(destination_dir)
      end

      def validate_country_codes!
        return if country_codes.all? { |country_code| country_code.match?(/\A[A-Z]{2}\z/) }

        raise Error, "country_codes must contain two-letter ISO codes"
      end

      def normalize_country_codes(value)
        Array(value)
          .flat_map { |item| item.to_s.split(",") }
          .map { |item| item.strip.upcase }
          .reject(&:blank?)
          .uniq
          .sort
      end

      def resolve_destination_dir(path)
        pathname = Pathname.new(path)
        pathname = Rails.root.join(pathname) if pathname.relative?
        pathname
      end
    end
  end
end
