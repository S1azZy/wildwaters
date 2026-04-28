require Rails.root.join("app/lib/imports/geo_names/region_dump_dataset_builder")
require Rails.root.join("app/lib/imports/geo_names/region_dump_downloader")

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
    geonames_config.country_codes.presence || raise(KeyError, "key not found: \"GEONAMES_COUNTRIES\"")
  end

  def normalized_languages
    geonames_config.languages
  end

  def normalized_feature_codes
    geonames_config.feature_codes
  end

  def include_alternate_names?
    geonames_config.download_alternate_names
  end

  def import_mode
    Imports::Run::MODES[:full]
  end

  def geonames_config
    ApplicationConfig.config.imports.geonames
  end
end

namespace :imports do
  namespace :geonames do
    desc "Enqueue queued GeoNames region import items"
    task enqueue: :environment do |rake_task|
      settings = Imports::GeoNames::Settings.from_env(initiated_by: rake_task.name)
      result = Imports::GeoNames::EnqueueRegionImport.call(input: settings.to_h)

      if result.failure?
        failure = result.failure
        raise "Unable to enqueue GeoNames import: #{failure[:code]}"
      end

      run = result.value!.fetch(:run)
      puts "Enqueued GeoNames region import run #{run.id}"
    end

    desc "Retry failed queued GeoNames region import items for RUN_ID"
    task retry_failed: :environment do
      run_id = ENV.fetch("RUN_ID").to_i
      result = Imports::GeoNames::RetryFailedItems.call(input: { import_run_id: run_id })

      if result.failure?
        failure = result.failure
        raise "Unable to retry failed GeoNames import items: #{failure[:code]}"
      end

      puts "Requeued failed GeoNames import items for run #{run_id}"
    end

    desc "Import region hierarchy from extracted GeoNames dump files"
    task regions: :environment do |rake_task|
      source = GeoNamesImportTasks.run_region_import!(
        source_key: GeoNamesImportTasks.geonames_config.source_key,
        country_codes: GeoNamesImportTasks.normalized_country_codes,
        languages: GeoNamesImportTasks.normalized_languages,
        feature_codes: GeoNamesImportTasks.normalized_feature_codes,
        initiated_by: rake_task.name,
        mode: GeoNamesImportTasks.import_mode,
        all_countries_path: GeoNamesImportTasks.geonames_config.all_countries_path,
        alternate_names_path: GeoNamesImportTasks.geonames_config.alternate_names_path.presence
      )

      puts "Imported GeoNames regions for #{GeoNamesImportTasks.normalized_country_codes.join(', ')} via source #{source.key}"
    end

    desc "Download official GeoNames country dumps, prepare local artifacts, and import region hierarchy"
    task regions_from_network: :environment do |rake_task|
      country_codes = GeoNamesImportTasks.normalized_country_codes
      source_key = GeoNamesImportTasks.geonames_config.source_key
      download_dir = GeoNamesImportTasks.geonames_config.download_dir
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
        initiated_by: rake_task.name,
        mode: GeoNamesImportTasks.import_mode,
        all_countries_path: downloaded_paths.fetch(:all_countries_path),
        alternate_names_path: downloaded_paths[:alternate_names_path]
      )

      puts "Downloaded GeoNames dumps to #{download_dir} and imported #{country_codes.join(', ')} via source #{source.key}"
    end
  end
end
