require "rails_helper"

RSpec.describe Regions::CreateRegion, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      name:,
      region_kind:,
      parent_id:,
      country_code: "ID",
      summary: "Editorial summary",
      description: "Longer editorial description"
    }
  end
  let(:name) { "Bali" }
  let(:region_kind) { "area" }
  let(:parent_id) { nil }

  describe "#call" do
    it "returns success" do
      expect(result).to be_success
    end

    it "creates a region" do
      expect { result }.to change(Region, :count).by(1)
    end

    it "creates a primary region name for search readiness" do
      expect { result }.to change(RegionName, :count).by(1)
    end

    it "creates the self closure row" do
      expect { result }.to change(RegionClosure, :count).by(1)
    end

    it "generates a public_id, slug, and country code" do
      result

      expect(result.value![:region]).to have_attributes(
        public_id: be_present,
        slug: "bali",
        country_code: "ID"
      )
    end

    it "persists the canonical primary name row" do
      result

      expect(result.value![:region].region_names.find_by!(name_role: "primary")).to have_attributes(
        name: "Bali",
        normalized_name: "bali",
        searchable: true
      )
    end

    context "when creating a child region" do
      let(:parent) { create(:region, name: "Indonesia", slug: "indonesia", region_kind: "country") }
      let(:name) { "Ubud" }
      let(:region_kind) { "locality" }
      let(:parent_id) { parent.id }

      before do
        create(:region_closure, ancestor: parent, descendant: parent, depth: 0)
      end

      it "creates inherited closure rows from the parent chain" do
        expect { result }.to change(RegionClosure, :count).by(2)
      end

      it "links the child region to the parent" do
        result

        expect(result.value![:region].parent).to eq(parent)
      end
    end

    context "when the region is invalid" do
      let(:name) { "" }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:validation_error)
      end

      it "does not create records" do
        expect { result }.not_to change { [ Region.count, RegionClosure.count ] }
      end
    end
  end
end
