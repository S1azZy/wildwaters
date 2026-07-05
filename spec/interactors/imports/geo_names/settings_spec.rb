require "rails_helper"

RSpec.describe Imports::GeoNames::Settings do
  include EnvHelpers

  subject(:result) { described_class.call(input:) }

  let(:input) { {} }
  let(:custom_input) do
    {
      countries: %w[ID],
      mode: Imports::Run::MODES[:full],
      initiated_by: "admin/imports/geonames#create"
    }
  end

  describe "#call" do
    around do |example|
      with_env(
        "GEONAMES_SOURCE_KEY" => "custom_geonames",
        "GEONAMES_COUNTRY_CODES" => "ad, fr",
        "GEONAMES_LANGUAGES" => "en, RU",
        "GEONAMES_FEATURE_CODES" => "PCLI, adm1",
        "GEONAMES_DOWNLOAD_ALTERNATE_NAMES" => "0",
        "GEONAMES_DEFAULT_MODE" => "replay",
        "GEONAMES_DOWNLOAD_DIR" => "tmp/imports/geonames/custom"
      ) do
        load Rails.root.join("config/initializers/01_settings.rb")
        example.run
      end
    ensure
      load Rails.root.join("config/initializers/01_settings.rb")
    end

    it "builds normalized enqueue input from environment-backed defaults" do
      expect(result).to be_success
      expect(result.value!).to eq(expected_input)
    end

    it "lets explicit input override environment defaults" do
      result = described_class.call(input: custom_input)

      expect(result.value!).to include(custom_input)
    end

    def expected_input
      {
        source_key: "custom_geonames",
        countries: %w[AD FR],
        languages: %w[en ru],
        feature_codes: %w[PCLI ADM1],
        download_alternate_names: false,
        mode: Imports::Run::MODES[:replay],
        download_dir: "tmp/imports/geonames/custom",
        initiated_by: described_class::DEFAULT_INITIATED_BY
      }
    end
  end
end
