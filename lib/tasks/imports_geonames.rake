require Rails.root.join("app/lib/imports/geonames/region_dump_dataset_builder")

namespace :imports do
  namespace :geonames do
    desc "Import region hierarchy from extracted GeoNames dump files"
    task regions: :environment do
      source_key = ENV.fetch("SOURCE_KEY", "geonames_regions")
      country_codes = ENV.fetch("COUNTRY_CODES").split(",").map(&:strip).reject(&:blank?)
      languages = ENV.fetch("LANGUAGES", "en,ru").split(",").map(&:strip).reject(&:blank?)
      feature_codes = ENV.fetch("FEATURE_CODES", Imports::GeoNames::RegionDumpDatasetBuilder::SUPPORTED_FEATURE_CODES.join(",")).split(",").map(&:strip).reject(&:blank?)

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
          "all_countries_path" => ENV.fetch("ALL_COUNTRIES_PATH"),
          "alternate_names_path" => ENV["ALTERNATE_NAMES_PATH"].presence,
          "country_codes" => country_codes,
          "languages" => languages,
          "feature_codes" => feature_codes
        }
      )
      source.save!

      Imports::RunSourceJob.perform_now(
        source_key: source.key,
        mode: ENV.fetch("MODE", Imports::Run::MODES[:full]),
        initiated_by: ENV.fetch("INITIATED_BY", "manual"),
        records: nil
      )

      puts "Imported GeoNames regions for #{country_codes.join(', ')} via source #{source.key}"
    end
  end
end
