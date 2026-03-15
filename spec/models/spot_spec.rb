require "rails_helper"

RSpec.describe Spot, type: :model do
  subject(:spot) { build(:spot) }

  describe "associations" do
    it { is_expected.to belong_to(:region) }
    it { is_expected.to have_one(:waterfall).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:spot_type) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:public_id) }
  end

  it "generates a public_id before validation" do
    spot = described_class.new(
      region: create(:region),
      name: "Sekumpul Waterfall",
      slug: "sekumpul-waterfall",
      spot_type: "waterfall",
      status: "draft",
      location: point(115.1245, -8.1791)
    )

    spot.validate

    expect(spot.public_id).to be_present
  end

  it "normalizes the slug before validation" do
    spot = build(:spot, slug: " Sekumpul Waterfall ")

    spot.validate

    expect(spot.slug).to eq("sekumpul-waterfall")
  end

  it "builds a public param with a double dash separator" do
    spot = build(:spot, public_id: "Ab3k9Lm2Qx7P", slug: "sekumpul-waterfall")

    expect(spot.to_param).to eq("Ab3k9Lm2Qx7P--sekumpul-waterfall")
  end

  it "allows the same slug in different regions" do
    create(:spot, region: create(:region, slug: "bali"), slug: "sekumpul-waterfall")

    spot = build(:spot, region: create(:region, slug: "lombok"), slug: "sekumpul-waterfall")

    expect(spot).to be_valid
  end

  it "rejects the same slug in the same region" do
    region = create(:region, slug: "bali")
    create(:spot, region:, slug: "sekumpul-waterfall")

    spot = build(:spot, region:, slug: "sekumpul-waterfall")

    expect(spot).not_to be_valid
    expect(spot.errors[:slug]).to include("has already been taken")
  end

  def point(longitude, latitude)
    RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude)
  end
end
