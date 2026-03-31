require "rails_helper"

RSpec.describe RegionName, type: :model do
  subject(:region_name) { build(:region_name) }

  describe "associations" do
    it { is_expected.to belong_to(:region) }
    it { is_expected.to belong_to(:import_source_record).class_name("Imports::SourceRecord").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:name_role) }
  end

  it "normalizes the name before validation" do
    region_name = build(:region_name, name: "  Bali  ")

    region_name.validate

    expect(region_name.name).to eq("Bali")
  end

  it "derives a normalized_name before validation" do
    region_name = build(:region_name, name: "  North   Bali ")

    region_name.validate

    expect(region_name.normalized_name).to eq("north bali")
  end

  it "rejects duplicate normalized names for the same region role and locale" do
    region = create(:region)
    create(:region_name, region:, language_code: "en", name_role: "primary", name: "Bali")

    duplicate = build(:region_name, region:, language_code: "en", name_role: "primary", name: "  bali ")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:normalized_name]).to include("has already been taken")
  end
end
