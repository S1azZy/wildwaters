require "rails_helper"

RSpec.describe Waterfall, type: :model do
  subject(:waterfall) { build(:waterfall) }

  describe "associations" do
    it { is_expected.to belong_to(:spot) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:spot_id).ignoring_case_sensitivity }
  end

  it "allows a positive height" do
    waterfall = build(:waterfall, height_meters: 15.5)

    expect(waterfall).to be_valid
  end

  it "rejects a negative height" do
    waterfall = build(:waterfall, height_meters: -1)

    expect(waterfall).not_to be_valid
    expect(waterfall.errors[:height_meters]).to include("must be greater than or equal to 0")
  end
end
