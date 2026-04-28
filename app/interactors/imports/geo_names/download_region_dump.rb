require "fileutils"
require "net/http"
require "pathname"
require "stringio"
require "uri"
require "zip"

module Imports
  module GeoNames
    class DownloadRegionDump < ApplicationInteractor
      option :input

      COUNTRY_DUMP_BASE_URL = "https://download.geonames.org/export/dump".freeze
      ALTERNATE_NAMES_BASE_URL = "https://download.geonames.org/export/dump/alternatenames".freeze
      DEFAULT_OPEN_TIMEOUT = 30
      DEFAULT_READ_TIMEOUT = 300

      class ValidationContract < ApplicationContract
        params do
          required(:country_code).filled(:string, format?: /\A[A-Za-z]{2}\z/)
          required(:destination_dir).filled(:string)
          optional(:include_alternate_names).filled(:bool)
        end
      end

      def call
        yield prepare_destination_dir

        all_countries_path = yield download_dump(
          output_filename: "all_countries.txt",
          base_url: COUNTRY_DUMP_BASE_URL
        )
        alternate_names_path = yield download_alternate_names_dump

        Success(
          {
            all_countries_path:,
            alternate_names_path:
          }.compact
        )
      end

      private

      def download_alternate_names_dump
        return Success(nil) unless input.fetch(:include_alternate_names, true)

        download_dump(
          output_filename: "alternate_names.txt",
          base_url: ALTERNATE_NAMES_BASE_URL
        )
      end

      def download_dump(output_filename:, base_url:)
        body = yield fetch_zip_body(base_url:)
        entry_contents = yield extract_entry(body:)
        output_path = yield write_dump_file(output_filename:, entry_contents:)

        Success(output_path)
      end

      def fetch_zip_body(base_url:)
        uri = URI("#{base_url}/#{country_code}.zip")
        response = yield fetch_response(uri)

        unless response.is_a?(Net::HTTPSuccess)
          return fail_with(
            code: :region_dump_download_failed,
            errors: { base: [ "Unable to download GeoNames dump for #{country_code} from #{uri} (HTTP #{response.code})" ] }
          )
        end

        Success(response.body)
      end

      def fetch_response(uri)
        safe_download_call do
          Net::HTTP.start(
            uri.host,
            uri.port,
            use_ssl: uri.scheme == "https",
            open_timeout: DEFAULT_OPEN_TIMEOUT,
            read_timeout: DEFAULT_READ_TIMEOUT
          ) do |http|
            request = Net::HTTP::Get.new(uri)
            http.request(request)
          end
        end
      end

      def extract_entry(body:)
        safe_zip_call do
          entry_name = "#{country_code}.txt"
          entry_contents = nil

          Zip::File.open_buffer(StringIO.new(body)) do |zip_file|
            entry = zip_file.find_entry(entry_name)
            raise Zip::Error, "Archive for #{country_code} does not contain #{entry_name}" unless entry

            entry_contents = entry.get_input_stream.read
          end

          entry_contents
        end
      end

      def write_dump_file(output_filename:, entry_contents:)
        safe_file_call do
          output_path = destination_dir.join(output_filename)

          File.open(output_path, "wb") do |output_file|
            output_file.write(entry_contents)
            output_file.write("\n") unless entry_contents.end_with?("\n")
          end

          output_path.to_s
        end
      end

      def prepare_destination_dir
        safe_file_call do
          FileUtils.mkdir_p(destination_dir)
        end
      end

      def safe_download_call(&)
        safe_call(
          IOError,
          Net::OpenTimeout,
          Net::ReadTimeout,
          SocketError,
          SystemCallError,
          on_error: ->(error) { download_failure(error.message) },
          &
        )
      end

      def safe_zip_call(&)
        safe_call(
          Zip::Error,
          on_error: ->(error) { download_failure("Unable to extract #{country_code}.txt from downloaded GeoNames archive: #{error.message}") },
          &
        )
      end

      def safe_file_call(&)
        safe_call(
          IOError,
          SystemCallError,
          on_error: ->(error) { download_failure(error.message) },
          &
        )
      end

      def download_failure(message)
        fail_with(code: :region_dump_download_failed, errors: { base: [ message ] })
      end

      def country_code
        @country_code ||= input.fetch(:country_code).upcase
      end

      def destination_dir
        @destination_dir ||= begin
          pathname = Pathname.new(input.fetch(:destination_dir))
          pathname = Rails.root.join(pathname) if pathname.relative?
          pathname
        end
      end
    end
  end
end
