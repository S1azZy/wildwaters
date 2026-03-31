require "rails_helper"

RSpec.describe Regions::SyncImportedRegion, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let!(:country) do
    create(:region, name: "Indonesia", slug: "indonesia", region_kind: "country").tap do |region|
      create(:region_closure, ancestor: region, descendant: region, depth: 0)
    end
  end
  let!(:old_parent) do
    create(:region, name: "Lesser Sunda", slug: "lesser-sunda", region_kind: "area", parent: country).tap do |region|
      create(:region_closure, ancestor: region, descendant: region, depth: 0)
      create(:region_closure, ancestor: country, descendant: region, depth: 1)
    end
  end
  let!(:new_parent) do
    create(:region, name: "Bali", slug: "bali", region_kind: "area", parent: country).tap do |region|
      create(:region_closure, ancestor: region, descendant: region, depth: 0)
      create(:region_closure, ancestor: country, descendant: region, depth: 1)
    end
  end
  let!(:region) do
    create(:region, name: "North Bali", slug: "north-bali", region_kind: "locality", parent: old_parent).tap do |record|
      create(:region_closure, ancestor: record, descendant: record, depth: 0)
      create(:region_closure, ancestor: old_parent, descendant: record, depth: 1)
      create(:region_closure, ancestor: country, descendant: record, depth: 2)
    end
  end
  let!(:child_region) do
    create(:region, name: "Sekumpul", slug: "sekumpul", region_kind: "locality", parent: region).tap do |record|
      create(:region_closure, ancestor: record, descendant: record, depth: 0)
      create(:region_closure, ancestor: region, descendant: record, depth: 1)
      create(:region_closure, ancestor: old_parent, descendant: record, depth: 2)
      create(:region_closure, ancestor: country, descendant: record, depth: 3)
    end
  end
  let(:input) do
    {
      region_id: region.id,
      parent_id: new_parent.id,
      name: "North Bali",
      region_kind: "locality",
      country_code: "ID",
      latitude: -8.1694,
      longitude: 115.1806
    }
  end

  it "reparents the region and rebuilds closure rows for the subtree" do
    expect(result).to be_success

    region.reload
    child_region.reload

    expect(region.parent).to eq(new_parent)
    expect(region.ancestor_closures.order(:depth).pluck(:ancestor_id, :depth)).to eq(
      [
        [ region.id, 0 ],
        [ new_parent.id, 1 ],
        [ country.id, 2 ]
      ]
    )
    expect(child_region.ancestor_closures.order(:depth).pluck(:ancestor_id, :depth)).to eq(
      [
        [ child_region.id, 0 ],
        [ region.id, 1 ],
        [ new_parent.id, 2 ],
        [ country.id, 3 ]
      ]
    )
  end
end
