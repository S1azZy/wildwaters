require "rails_helper"
require Rails.root.join("app/lib/imports/geonames/region_dump_dataset_builder")

RSpec.describe Imports::GeoNames::RegionDumpDatasetBuilder do
  subject(:records) { described_class.call(config:) }

  let(:all_countries_path) { Rails.root.join("tmp/geonames_region_dump_builder_all_countries.txt") }
  let(:alternate_names_path) { Rails.root.join("tmp/geonames_region_dump_builder_alternate_names.txt") }
  let(:config) do
    {
      all_countries_path: all_countries_path.to_s,
      alternate_names_path: alternate_names_path.to_s,
      country_codes: [ "ID" ],
      languages: [ "ru" ]
    }
  end

  before do
    all_countries_path.dirname.mkpath
    all_countries_path.write(
      [
        "1643084\tIndonesia\tIndonesia\tIndonesia\t-2.5\t118.0\tA\tPCLI\tID\t\t\t\t\t\t0\t\t\tAsia/Jakarta\t2024-01-01",
        "1650535\tBali\tBali\tBali\t-8.4095\t115.1889\tA\tADM1\tID\t\t02\t\t\t\t0\t\t\tAsia/Jakarta\t2024-01-01",
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
    expect(records.map { |record| record[:external_uid] }).to eq(%w[1643084 1650535 1651111])

    expect(records.second).to include(
      name: "Bali",
      region_kind: "area",
      country_code: "ID",
      parent_external_uid: "1643084"
    )
    expect(records.third).to include(
      name: "Singaraja",
      region_kind: "locality",
      parent_external_uid: "1650535"
    )
    expect(records.third[:alternate_names]).to contain_exactly(
      {
        language_code: "ru",
        name: "Сингараджа",
        name_role: "alias"
      }
    )
  end

  it "fails clearly when required config is missing" do
    expect do
      described_class.call(config: { languages: [ "ru" ] })
    end.to raise_error(ArgumentError, "all_countries_path is required")
  end
end
