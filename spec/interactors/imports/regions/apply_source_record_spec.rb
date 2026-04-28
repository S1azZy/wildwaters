require "rails_helper"

RSpec.describe Imports::Regions::ApplySourceRecord, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:source) { create(:imports_source, key: "geonames_regions") }
  let(:run) { create(:imports_run, import_source: source) }
  let(:record) do
    {
      record_kind: "region",
      external_uid: "1643084",
      external_url: "https://www.geonames.org/1643084",
      name: "Indonesia",
      ascii_name: "Indonesia",
      region_kind: "country",
      country_code: "ID",
      parent_external_uid: nil,
      latitude: -2.5,
      longitude: 118.0,
      alternate_names: []
    }
  end
  let(:input) { { source:, run:, record: } }

  context "when required input is missing" do
    let(:input) { { source:, run: } }

    it "returns a validation failure before touching persistence" do
      expect { result }.not_to change(Imports::SourceRecord, :count)
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(record: [ "is missing" ])
    end
  end
end
