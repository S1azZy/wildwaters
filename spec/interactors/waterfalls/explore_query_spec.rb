require "rails_helper"

RSpec.describe Waterfalls::ExploreQuery, type: :interactor do
  subject(:result) { described_class.call(**call_args) }

  let(:bali) { create_region(name: "Bali", region_type: Region::REGION_TYPES[:admin_area]) }
  let(:north_bali) do
    create_region(name: "North Bali", region_type: Region::REGION_TYPES[:locality], parent_id: bali.id)
  end
  let!(:matching_waterfall) do
    create(
      :waterfall,
      height_meters: 80.0,
      plunge_pool: "true",
      approach_difficulty: "moderate",
      spot: create(
        :spot,
        :published,
        region: north_bali,
        name: "Sekumpul Waterfall",
        location: point(115.1806, -8.1694)
      )
    )
  end
  let!(:filtered_out_by_height) do
    create(
      :waterfall,
      height_meters: 35.0,
      plunge_pool: false,
      approach_difficulty: "moderate",
      spot: create(
        :spot,
        :published,
        region: north_bali,
        name: "Gitgit Waterfall",
        location: point(115.1415, -8.1883)
      )
    )
  end
  let!(:filtered_out_by_bounds) do
    create(
      :waterfall,
      height_meters: 90.0,
      plunge_pool: "true",
      approach_difficulty: "moderate",
      spot: create(
        :spot,
        :published,
        region: bali,
        name: "Far Away Falls",
        location: point(116.4039, -8.4021)
      )
    )
  end
  let!(:draft_waterfall) do
    create(
      :waterfall,
      spot: create(
        :spot,
        region: north_bali,
        name: "Hidden Draft Falls",
        location: point(115.182, -8.17)
      )
    )
  end
  let(:input) do
    {
      west: "115.0",
      south: "-8.3",
      east: "115.3",
      north: "-8.0",
      region_public_id: north_bali.public_id,
      min_height_meters: "50.0",
      plunge_pool: "true",
      approach_difficulty: "moderate"
    }
  end
  let(:call_args) { { input:, require_bounds: } }
  let(:require_bounds) { false }

  it "returns success" do
    expect(result).to be_success
  end

  it "returns published waterfalls matching the active explore filters" do
    expect(result).to be_success
    expect(result.value!.fetch(:waterfalls)).to eq([ matching_waterfall ])
  end

  context "when input is empty" do
    let(:input) { {} }

    it "returns success with the published catalog" do
      expect(result).to be_success
      waterfalls = result.value!.fetch(:waterfalls)

      expect(waterfalls).to include(matching_waterfall, filtered_out_by_height, filtered_out_by_bounds)
      expect(waterfalls).not_to include(draft_waterfall)
    end
  end

  context "when input is omitted" do
    let(:call_args) { { require_bounds: } }

    it "returns success with the published catalog" do
      expect(result).to be_success
      waterfalls = result.value!.fetch(:waterfalls)

      expect(waterfalls).to include(matching_waterfall, filtered_out_by_height, filtered_out_by_bounds)
      expect(waterfalls).not_to include(draft_waterfall)
    end
  end

  context "when bounds are malformed" do
    let(:input) do
      {
        west: "abc",
        south: "-8.3",
        east: "115.3",
        north: "-8.0"
      }
    end

    it "returns failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
    end
  end

  context "when bounds are incomplete" do
    let(:input) do
      {
        west: "115.0",
        south: "-8.3",
        east: "115.3"
      }
    end

    it "returns failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
    end
  end

  context "when bounds are absent" do
    let(:input) do
      {
        region_public_id: north_bali.public_id
      }
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "returns published waterfalls matching non-spatial filters" do
      expect(result).to be_success
      expect(result.value!.fetch(:waterfalls)).to contain_exactly(matching_waterfall, filtered_out_by_height)
    end
  end

  context "when filtering for waterfalls without plunge pools" do
    let(:input) do
      {
        west: "115.0",
        south: "-8.3",
        east: "115.3",
        north: "-8.0",
        plunge_pool: "false"
      }
    end

    it "returns only waterfalls without plunge pools" do
      expect(result).to be_success
      waterfalls = result.value!.fetch(:waterfalls)

      expect(waterfalls).to include(filtered_out_by_height)
      expect(waterfalls).not_to include(matching_waterfall, filtered_out_by_bounds, draft_waterfall)
      expect(waterfalls.map(&:plunge_pool).uniq).to eq([ false ])
    end
  end

  context "when the filter set is empty" do
    let(:input) { {} }

    it "returns success" do
      expect(result).to be_success
    end

    it "returns all published waterfalls" do
      expect(result).to be_success
      waterfalls = result.value!.fetch(:waterfalls)

      expect(waterfalls).to include(matching_waterfall, filtered_out_by_height, filtered_out_by_bounds)
      expect(waterfalls).not_to include(draft_waterfall)
    end
  end

  context "when bounds are required but absent" do
    let(:input) { { region_public_id: north_bali.public_id } }
    let(:require_bounds) { true }

    it "returns failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
    end
  end

  def point(longitude, latitude)
    RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude)
  end

  def create_region(name:, region_type:, parent_id: nil)
    result = Regions::CreateRegion.call(
      input: {
        name:,
        region_type:,
        parent_id:
      }
    )

    result.value![:region]
  end
end
