require "rails_helper"

RSpec.describe Spots::CreateWaterfall, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      region_id: region.id,
      name:,
      summary: "Short waterfall summary",
      description: "Longer waterfall description",
      latitude: -8.2561,
      longitude: 115.1606,
      height_meters: 15.5,
      plunge_pool: true,
      flow_seasonality: "year_round",
      approach_difficulty: "moderate",
      status: "draft"
    }
  end
  let(:region) { create(:region, name: "Bali", slug: "bali", region_type: "admin_area") }
  let(:name) { "Tegenungan Waterfall" }

  describe "#call" do
    it "returns success" do
      expect(result).to be_success
    end

    it "creates a spot and waterfall" do
      expect { result }.to change(Spot, :count).by(1)
        .and change(Waterfall, :count).by(1)
    end

    it "returns the created records" do
      result

      expect(result.value!).to include(
        spot: have_attributes(name:, spot_type: "waterfall", region:),
        waterfall: have_attributes(height_meters: BigDecimal("15.5"))
      )
    end

    it "generates a public_id and slug" do
      result

      expect(result.value![:spot]).to have_attributes(
        public_id: be_present,
        slug: "tegenungan-waterfall"
      )
    end

    it "persists the expected point location" do
      result

      location = result.value![:spot].location

      expect(location.x).to eq(115.1606)
      expect(location.y).to eq(-8.2561)
    end

    context "when the region does not exist" do
      let(:input) { super().merge(region_id: SecureRandom.uuid) }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:region_not_found)
      end

      it "does not create records" do
        expect { result }.not_to change { [ Spot.count, Waterfall.count ] }
      end
    end

    context "when the waterfall is invalid" do
      let(:input) { super().merge(height_meters: -1) }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:validation_error)
      end

      it "rolls back the spot" do
        expect { result }.not_to change { [ Spot.count, Waterfall.count ] }
      end
    end
  end
end
