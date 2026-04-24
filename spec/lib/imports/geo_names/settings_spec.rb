require "rails_helper"

RSpec.describe Imports::GeoNames::Settings do
  include EnvHelpers

  describe ".from_env" do
    around do |example|
      with_env(
        "GEONAMES_SOURCE_KEY" => "custom_geonames",
        "GEONAMES_COUNTRIES" => "ad, fr",
        "GEONAMES_LANGUAGES" => "en, RU",
        "GEONAMES_FEATURE_CODES" => "PCLI, adm1",
        "GEONAMES_DOWNLOAD_ALTERNATE_NAMES" => "0",
        "GEONAMES_DEFAULT_MODE" => "replay",
        "GEONAMES_QUEUE" => "imports",
        "GEONAMES_DOWNLOAD_DIR" => "tmp/imports/geonames/custom"
      ) do
        load Rails.root.join("config/initializers/01_settings.rb")
        example.run
      end
    ensure
      load Rails.root.join("config/initializers/01_settings.rb")
    end

    it "builds normalized enqueue input from environment-backed defaults" do
      settings = described_class.from_env(initiated_by: "imports:geonames:enqueue")

      expect(settings.to_h).to eq(
        source_key: "custom_geonames",
        countries: %w[AD FR],
        languages: %w[en ru],
        feature_codes: %w[PCLI ADM1],
        download_alternate_names: false,
        mode: Imports::Run::MODES[:replay],
        queue: "imports",
        download_dir: "tmp/imports/geonames/custom",
        initiated_by: "imports:geonames:enqueue"
      )
    end

    it "lets explicit input override environment defaults" do
      settings = described_class.from_env(
        initiated_by: "admin/imports/geonames#create",
        overrides: {
          countries: %w[ID],
          mode: Imports::Run::MODES[:full]
        }
      )

      expect(settings.to_h).to include(
        countries: %w[ID],
        mode: Imports::Run::MODES[:full],
        initiated_by: "admin/imports/geonames#create"
      )
    end
  end
end
