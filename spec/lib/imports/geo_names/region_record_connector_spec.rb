require "rails_helper"

RSpec.describe Imports::GeoNames::RegionRecordConnector do
  subject(:records) { described_class.call(records: raw_records) }

  let(:raw_records) do
    [
      {
        external_uid: "1650535",
        external_url: "https://www.geonames.org/1650535",
        record_kind: "region",
        name: "  Bali  ",
        ascii_name: " Bali ",
        region_kind: "area",
        country_code: " id ",
        parent_external_uid: "1643084",
        latitude: -8.4095,
        longitude: 115.1889,
        alternate_names: [
          { language_code: "RU", name: " Бали ", name_role: "preferred" },
          { language_code: nil, name: " Bali Island ", name_role: nil }
        ]
      },
      {
        external_uid: "1643084",
        external_url: "https://www.geonames.org/1643084",
        record_kind: "region",
        name: "Indonesia",
        ascii_name: "Indonesia",
        region_kind: "country",
        country_code: "ID",
        parent_external_uid: nil,
        latitude: -2.5,
        longitude: 118.0,
        alternate_names: []
      }
    ]
  end

  it "sorts parents before descendants" do
    expect(records.map { |record| record[:external_uid] }).to eq(%w[1643084 1650535])
  end

  it "normalizes canonical and alternate names for import application" do
    expect(records.last).to include(name: "Bali", ascii_name: "Bali", country_code: "ID", region_kind: "area", parent_external_uid: "1643084")
    expect(records.last[:alternate_names]).to contain_exactly(
      { language_code: "ru", name: "Бали", name_role: "preferred" },
      { language_code: nil, name: "Bali Island", name_role: "alias" }
    )
  end
end
