require "rails_helper"

RSpec.describe Imports::RegionSourceLink, type: :model do
  subject(:region_source_link) { build(:imports_region_source_link) }

  describe "associations" do
    it { is_expected.to belong_to(:region) }
    it { is_expected.to belong_to(:import_source_record).class_name("Imports::SourceRecord") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:match_strategy) }
    it { is_expected.to validate_presence_of(:confidence) }
    it { is_expected.to validate_uniqueness_of(:import_source_record_id) }
  end

  it "allows only one primary identity link per region" do
    region = create(:region)
    create(:imports_region_source_link, region:, primary_identity: true)

    duplicate = build(:imports_region_source_link, region:, primary_identity: true)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:region_id]).to include("already has a primary identity")
  end

  it "rejects a primary identity link from a non-canonical source" do
    source = create(:imports_source, source_role: "name_enrichment")
    source_record = create(:imports_source_record, import_source: source)

    region_source_link = build(
      :imports_region_source_link,
      import_source_record: source_record,
      primary_identity: true
    )

    expect(region_source_link).not_to be_valid
    expect(region_source_link.errors[:primary_identity]).to include("requires a canonical identity source")
  end
end
