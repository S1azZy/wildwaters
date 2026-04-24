require "rails_helper"

RSpec.describe ApplicationConfig do
  after do
    described_class.load_from_env!
  end

  it "loads typed URL settings from environment overrides" do
    with_application_env do
      described_class.load_from_env!

      aggregate_failures do
        expect(described_class.config.urls.host).to eq("wild.example.test")
        expect(described_class.config.urls.port).to eq(3443)
        expect(described_class.config.urls.protocol).to eq("https")
      end
    end
  end

  it "loads typed GeoNames import settings from environment overrides" do
    with_application_env do
      described_class.load_from_env!

      aggregate_failures do
        expect(described_class.config.imports.geonames.source_key).to eq("custom_geonames")
        expect(described_class.config.imports.geonames.country_codes).to eq(%w[AD FR])
        expect(described_class.config.imports.geonames.languages).to eq(%w[en ru])
        expect(described_class.config.imports.geonames.feature_codes).to eq(%w[PCLI ADM1])
        expect(described_class.config.imports.geonames.download_alternate_names).to be(false)
        expect(described_class.config.imports.geonames.mode).to eq("replay")
      end
    end
  end

  it "allows configured storage service names" do
    with_env("ACTIVE_STORAGE_SERVICE" => "amazon") do
      described_class.load_from_env!

      expect(described_class.config.storage.service).to eq(:amazon)
    end
  end

  def with_application_env(&)
    with_env(
      "APP_HOST" => "wild.example.test",
      "APP_PORT" => "3443",
      "APP_PROTOCOL" => "https",
      "GEONAMES_SOURCE_KEY" => "custom_geonames",
      "GEONAMES_COUNTRY_CODES" => "ad, fr",
      "GEONAMES_LANGUAGES" => "en, RU",
      "GEONAMES_FEATURE_CODES" => "PCLI, ADM1",
      "GEONAMES_DOWNLOAD_ALTERNATE_NAMES" => "0",
      "GEONAMES_DOWNLOAD_DIR" => "tmp/imports/geonames/custom",
      "GEONAMES_INITIATED_BY" => "scheduler",
      "GEONAMES_MODE" => "replay",
      &
    )
  end
end
