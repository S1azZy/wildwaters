require "rails_helper"

RSpec.describe Imports::GeoNames::BuildRegionDataset, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      country_codes: [ "AD" ],
      languages: %w[en ru ca fr es],
      feature_codes: %w[PCLI ADM1 PPLA PPLC],
      all_countries_path: "spec/fixtures/imports/geonames/country_AD.txt",
      alternate_names_path: "spec/fixtures/imports/geonames/alternate_names_AD.txt"
    }
  end

  it "builds normalized region records from dump artifact paths" do
    expect(result).to be_success
    expect(result.value!.fetch(:records).size).to eq(15)
    expect(result.value!.fetch(:records)).to include(
      include(
        record_kind: "region",
        external_uid: "3041565",
        country_code: "AD"
      )
    )
  end

  context "when required input is missing" do
    let(:input) { { country_codes: [ "AD" ] } }

    it "returns validation failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(all_countries_path: [ "is missing" ])
    end
  end

  context "when the dump file cannot be read" do
    let(:input) { super().merge(all_countries_path: "tmp/missing-geonames-file.txt") }

    it "returns a dataset build failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:region_dataset_build_failed)
      expect(result.failure[:errors].fetch(:base).first).to include("No such file")
    end
  end
end
