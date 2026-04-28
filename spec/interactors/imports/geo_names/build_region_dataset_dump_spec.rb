require "rails_helper"

RSpec.describe Imports::GeoNames::BuildRegionDataset, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:records) { result.value!.fetch(:records) }

  let(:all_countries_path) { Rails.root.join("tmp/geonames_region_dump_builder_all_countries.txt") }
  let(:alternate_names_path) { Rails.root.join("tmp/geonames_region_dump_builder_alternate_names.txt") }
  let(:input) do
    {
      all_countries_path: all_countries_path.to_s,
      alternate_names_path: alternate_names_path.to_s,
      country_codes: [ "ID" ],
      languages: [ "ru" ]
    }
  end
  let(:country) { records.find { |record| record[:external_uid] == "3041565" } }
  let(:ordino_area) { records.find { |record| record[:external_uid] == "3039676" } }
  let(:ordino_locality) { records.find { |record| record[:external_uid] == "3039678" } }

  before do
    all_countries_path.dirname.mkpath
    all_countries_path.write(
      [
        "1650535\tBali\tBali\tBali\t-8.4095\t115.1889\tA\tADM1\tID\t\t02\t\t\t\t0\t\t\tAsia/Jakarta\t2024-01-01",
        "1643084\tIndonesia\tIndonesia\tIndonesia\t-2.5\t118.0\tA\tPCLI\tID\t\t\t\t\t\t0\t\t\tAsia/Jakarta\t2024-01-01",
        "1651111\tSingaraja\tSingaraja\tSingaraja\t-8.112\t115.088\tP\tPPL\tID\t\t02\t\t\t\t0\t\t\tAsia/Jakarta\t2024-01-01"
      ].join("\n")
    )
    alternate_names_path.write(
      [
        "1\t1650535\tru\tБали\t1\t0\t0\t0\t\t",
        "2\t1651111\tru\tСингараджа\t0\t0\t0\t0\t\t",
        "3\t1651111\ten\tSingaraja\t1\t0\t0\t0\t\t"
      ].join("\n")
    )
  end

  after do
    all_countries_path.delete if all_countries_path.exist?
    alternate_names_path.delete if alternate_names_path.exist?
  end

  it "builds normalized region records from extracted GeoNames files" do
    expect(result).to be_success
    expect(records.map { |record| record[:external_uid] }).to eq(%w[1643084 1650535])
    expect(records.second).to include(name: "Bali", region_kind: "area", country_code: "ID", parent_external_uid: "1643084")
    expect(records.map { |record| record[:name] }).not_to include("Singaraja")
  end

  it "fails clearly when required config is missing" do
    failure = described_class.call(input: { languages: [ "ru" ], country_codes: [ "ID" ] })

    expect(failure).to be_failure
    expect(failure.failure[:code]).to eq(:validation_error)
    expect(failure.failure[:errors]).to include(all_countries_path: [ "is missing" ])
  end

  context "with the official GeoNames Andorra fixtures" do
    let(:input) do
      {
        all_countries_path: "spec/fixtures/imports/geonames/country_AD.txt",
        alternate_names_path: "spec/fixtures/imports/geonames/alternate_names_AD.txt",
        country_codes: [ "AD" ],
        languages: [ "en", "ru" ]
      }
    end

    it "loads the real GeoNames fixture size through the dump builder" do
      expect(records.size).to eq(15)
    end

    it "maps the official country and hierarchy records into the normalized dataset" do
      expect(country).to include(name: "Principality of Andorra", region_kind: "country", parent_external_uid: nil)
      expect(ordino_area).to include(name: "Ordino", region_kind: "area", parent_external_uid: "3041565")
      expect(ordino_locality).to include(name: "Ordino", region_kind: "locality", parent_external_uid: "3039676")
    end

    it "extracts multilingual alternate names from the official alternate-names fixture" do
      expect(country[:alternate_names]).to include(
        { language_code: "en", name: "Andorra", name_role: "preferred" },
        { language_code: "ru", name: "Андорра", name_role: "preferred" }
      )
    end
  end
end
