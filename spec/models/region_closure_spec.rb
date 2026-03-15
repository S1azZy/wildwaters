require "rails_helper"

RSpec.describe RegionClosure, type: :model do
  subject(:region_closure) { build(:region_closure) }

  describe "associations" do
    it { is_expected.to belong_to(:ancestor).class_name("Region") }
    it { is_expected.to belong_to(:descendant).class_name("Region") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:depth) }
    it { is_expected.to validate_uniqueness_of(:ancestor_id).scoped_to(:descendant_id).ignoring_case_sensitivity }
  end
end
