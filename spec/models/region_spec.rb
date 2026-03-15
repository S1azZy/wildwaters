require "rails_helper"

RSpec.describe Region, type: :model do
  subject(:region) { build(:region) }

  describe "associations" do
    it { is_expected.to belong_to(:parent).class_name("Region").optional }
    it { is_expected.to have_many(:children).class_name("Region").with_foreign_key(:parent_id).dependent(:nullify) }
    it { is_expected.to have_many(:ancestor_closures).class_name("RegionClosure").with_foreign_key(:descendant_id).dependent(:destroy) }
    it { is_expected.to have_many(:descendant_closures).class_name("RegionClosure").with_foreign_key(:ancestor_id).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:region_type) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:public_id) }
  end

  it "generates a public_id before validation" do
    region = described_class.new(name: "Bali", slug: "bali", region_type: "country", status: "active")

    region.validate

    expect(region.public_id).to be_present
  end

  it "normalizes the slug before validation" do
    region = build(:region, slug: " Bali Island ")

    region.validate

    expect(region.slug).to eq("bali-island")
  end

  it "allows the same slug under different parents" do
    parent_a = create(:region, slug: "indonesia")
    parent_b = create(:region, slug: "thailand")
    create(:region, parent: parent_a, slug: "ubud")

    region = build(:region, parent: parent_b, slug: "ubud")

    expect(region).to be_valid
  end

  it "rejects the same slug under the same parent" do
    parent = create(:region, slug: "indonesia")
    create(:region, parent:, slug: "ubud")

    region = build(:region, parent:, slug: "ubud")

    expect(region).not_to be_valid
    expect(region.errors[:slug]).to include("has already been taken")
  end
end
