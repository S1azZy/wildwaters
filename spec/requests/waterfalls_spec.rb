require "rails_helper"

RSpec.describe "Waterfalls", type: :request do
  describe "GET /" do
    subject(:perform_request) { get root_path }

    let(:published_waterfall) do
      create(:waterfall, spot: create(:spot, :published, name: "Sekumpul Waterfall"))
    end

    before do
      published_waterfall
    end

    it "renders the public waterfall catalog" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sekumpul Waterfall")
    end
  end

  describe "GET /waterfalls" do
    subject(:perform_request) { get waterfalls_path }

    let(:published_waterfall) do
      create(:waterfall, spot: create(:spot, :published, name: "Sekumpul Waterfall"))
    end
    let(:draft_waterfall) do
      create(:waterfall, spot: create(:spot, name: "Hidden Falls"))
    end

    before do
      published_waterfall
      draft_waterfall
    end

    it "shows published waterfalls" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sekumpul Waterfall")
    end

    it "hides draft waterfalls" do
      perform_request

      expect(response.body).not_to include("Hidden Falls")
    end
  end

  describe "GET /waterfalls/:slugged_public_id" do
    subject(:perform_request) { get waterfall_path(slugged_public_id) }

    let!(:waterfall) do
      create(
        :waterfall,
        height_meters: 80.0,
        plunge_pool: true,
        flow_seasonality: "year_round",
        approach_difficulty: "moderate",
        spot: create(
          :spot,
          :published,
          name: "Sekumpul Waterfall",
          summary: "Twin cascades in North Bali.",
          description: "A dramatic jungle waterfall.",
          slug: "sekumpul-waterfall"
        )
      )
    end
    let(:slugged_public_id) { "#{waterfall.spot.public_id}-wrong-slug" }

    it "resolves the waterfall by public id" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sekumpul Waterfall")
      expect(response.body).to include("Twin cascades in North Bali.")
    end

    it "returns not found for draft waterfalls" do
      waterfall.spot.update!(status: Spot::STATUSES[:draft], published_at: nil)

      perform_request

      expect(response).to have_http_status(:not_found)
    end

    context "when the waterfall does not exist" do
      let(:slugged_public_id) { "missing-sekumpul-waterfall" }

      it "returns not found" do
        perform_request

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
