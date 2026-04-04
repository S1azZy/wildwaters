require "rails_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "db/seeds.rb" do
  before do
    Waterfall.delete_all
    Spot.delete_all
    RegionClosure.delete_all
    RegionName.delete_all
    Imports::RegionSourceLink.delete_all
    Imports::RecordSnapshot.delete_all
    Imports::SourceRecord.delete_all
    Imports::Run.delete_all
    Region.delete_all
    Imports::Source.delete_all
  end

  it "disables automatic seeding during db:prepare for the test database" do
    expect(ActiveRecord::Base.configurations.configs_for(env_name: "test").all?(&:seeds?)).to be(false)
  end

  it "does not seed demo data in the test environment" do
    expect { load Rails.root.join("db/seeds.rb") }.not_to change {
      [ Imports::Source.count, Region.count, Spot.count, Waterfall.count ]
    }
  end
end
# rubocop:enable RSpec/DescribeClass
