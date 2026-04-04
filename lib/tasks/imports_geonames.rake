require Rails.root.join("app/lib/imports/geonames/region_dump_dataset_builder")
require Rails.root.join("app/lib/imports/geonames/region_dump_downloader")

module GeoNamesImportTasks
  module_function

  def run_region_import!(
    source_key:,
    country_codes:,
    languages:,
    feature_codes:,
    initiated_by:,
    mode:,
    all_countries_path:,
    alternate_names_path:
  )
    source = Imports::Source.find_or_initialize_by(key: source_key)
    source.assign_attributes(
      target_kind: "region",
      source_role: Imports::Source::SOURCE_ROLES[:canonical_identity],
      fetch_mode: Imports::Source::FETCH_MODES[:dump],
      enabled: true,
      license_key: "geonames",
      license_url: "https://www.geonames.org/export/",
      attribution_text: "GeoNames",
      display_policy: Imports::Source::DISPLAY_POLICIES[:public_display_allowed],
      config: {
        "all_countries_path" => all_countries_path,
        "alternate_names_path" => alternate_names_path,
        "country_codes" => country_codes,
        "languages" => languages,
        "feature_codes" => feature_codes
      }
    )
    source.save!

    Imports::RunSourceJob.perform_now(
      source_key: source.key,
      mode:,
      initiated_by:,
      records: nil
    )

    source
  end

  def normalized_country_codes
    ENV.fetch("COUNTRY_CODES").split(",").map { |value| value.strip.upcase }.reject(&:blank?)
  end

  def normalized_languages
    ENV.fetch("LANGUAGES", "en,ru").split(",").map { |value| value.strip.downcase }.reject(&:blank?)
  end

  def normalized_feature_codes
    ENV.fetch(
      "FEATURE_CODES",
      Imports::GeoNames::RegionDumpDatasetBuilder::SUPPORTED_FEATURE_CODES.join(",")
    ).split(",").map { |value| value.strip }.reject(&:blank?)
  end

  def include_alternate_names?
    ENV.fetch("DOWNLOAD_ALTERNATE_NAMES", "1") != "0"
  end
end

namespace :imports do
  namespace :geonames do
    desc "Import region hierarchy from extracted GeoNames dump files"
    task regions: :environment do
      source = GeoNamesImportTasks.run_region_import!(
        source_key: ENV.fetch("SOURCE_KEY", "geonames_regions"),
        country_codes: GeoNamesImportTasks.normalized_country_codes,
        languages: GeoNamesImportTasks.normalized_languages,
        feature_codes: GeoNamesImportTasks.normalized_feature_codes,
        initiated_by: ENV.fetch("INITIATED_BY", "manual"),
        mode: ENV.fetch("MODE", Imports::Run::MODES[:full]),
        all_countries_path: ENV.fetch("ALL_COUNTRIES_PATH"),
        alternate_names_path: ENV["ALTERNATE_NAMES_PATH"].presence
      )

      puts "Imported GeoNames regions for #{GeoNamesImportTasks.normalized_country_codes.join(', ')} via source #{source.key}"
    end

    desc "Download official GeoNames country dumps, prepare local artifacts, and import region hierarchy"
    task regions_from_network: :environment do
      country_codes = GeoNamesImportTasks.normalized_country_codes
      source_key = ENV.fetch("SOURCE_KEY", "geonames_regions")
      download_dir = ENV.fetch("DOWNLOAD_DIR", "tmp/imports/geonames/#{source_key}")
      downloaded_paths = Imports::GeoNames::RegionDumpDownloader.call(
        country_codes:,
        destination_dir: download_dir,
        include_alternate_names: GeoNamesImportTasks.include_alternate_names?
      )

      source = GeoNamesImportTasks.run_region_import!(
        source_key:,
        country_codes:,
        languages: GeoNamesImportTasks.normalized_languages,
        feature_codes: GeoNamesImportTasks.normalized_feature_codes,
        initiated_by: ENV.fetch("INITIATED_BY", "manual"),
        mode: ENV.fetch("MODE", Imports::Run::MODES[:full]),
        all_countries_path: downloaded_paths.fetch(:all_countries_path),
        alternate_names_path: downloaded_paths[:alternate_names_path]
      )

      puts "Downloaded GeoNames dumps to #{download_dir} and imported #{country_codes.join(', ')} via source #{source.key}"
    end
  end
end
