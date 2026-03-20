require "json"
require "net/http"
require "pathname"
require "uri"

module MaplibreVersionCheck
  class Error < StandardError; end

  VERSION_PATTERN = %r{blob/v(?<version>\d+\.\d+\.\d+)/LICENSE\.txt}.freeze
  DEFAULT_LOCAL_ASSET_PATH = Pathname(__dir__).join("../vendor/javascript/maplibre-gl.js").expand_path.freeze
  DEFAULT_REGISTRY_URL = "https://registry.npmjs.org/maplibre-gl/latest"

  module_function

  def call(local_asset_path: DEFAULT_LOCAL_ASSET_PATH, latest_version_fetcher: method(:fetch_latest_version))
    local_version = parse_version(File.read(local_asset_path))
    latest_version = latest_version_fetcher.call

    {
      local_version:,
      latest_version:,
      up_to_date: local_version == latest_version
    }
  rescue Errno::ENOENT => error
    raise Error, "Unable to read vendored maplibre-gl asset: #{error.message}"
  end

  def run_cli(stdout: $stdout, stderr: $stderr, checker: method(:call))
    result = checker.call

    if result.fetch(:up_to_date)
      stdout.puts("maplibre-gl is up to date (local #{result.fetch(:local_version)}, latest #{result.fetch(:latest_version)}).")
      return 0
    end

    stderr.puts("maplibre-gl is outdated (local #{result.fetch(:local_version)}, latest #{result.fetch(:latest_version)}).")
    1
  rescue Error => error
    stderr.puts("maplibre-gl check failed: #{error.message}")
    1
  end

  def parse_version(contents)
    contents.match(VERSION_PATTERN)&.[](:version) || raise(
      Error,
      "Unable to parse maplibre-gl version from vendored asset"
    )
  end

  def parse_registry_version(body)
    version = JSON.parse(body).fetch("version", nil)

    return version if version.is_a?(String) && version.match?(/\A\d+\.\d+\.\d+\z/)

    raise Error, "Unable to parse latest maplibre-gl version from npm registry"
  rescue JSON::ParserError => error
    raise Error, "Unable to parse latest maplibre-gl version from npm registry: #{error.message}"
  end

  def fetch_latest_version(registry_url: DEFAULT_REGISTRY_URL)
    response = Net::HTTP.get_response(URI(registry_url))

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Unable to fetch latest maplibre-gl version from npm registry (HTTP #{response.code})"
    end

    parse_registry_version(response.body)
  rescue Error
    raise
  rescue StandardError => error
    raise Error, "Unable to fetch latest maplibre-gl version from npm registry: #{error.message}"
  end
end
