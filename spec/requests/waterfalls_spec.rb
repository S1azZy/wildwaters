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

    it "renders the public explore shell" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="explore-map"')
      expect(response.body).to include("Sign in")
      expect(response.body).to include("Sekumpul Waterfall")
    end

    it "sets a content security policy for the map experience" do
      perform_request

      script_sources = content_security_policy_directives.fetch("script-src")
      style_sources = content_security_policy_directives.fetch("style-src")

      expect(response).to have_http_status(:ok)
      expect(content_security_policy_directives.fetch("default-src")).to eq([ "'self'" ])
      expect(script_sources).to satisfy { |values| values.include?("'self'") && !values.include?("https://unpkg.com") }
      expect(style_sources).to satisfy { |values| values.include?("'self'") && !values.include?("https://unpkg.com") }
      expect(content_security_policy_directives.fetch("connect-src")).to include("'self'", "https://demotiles.maplibre.org")
      expect(content_security_policy_directives.fetch("worker-src")).to include("'self'", "blob:")
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

  describe "GET /waterfalls with explore filters" do
    subject(:perform_request) { get waterfalls_path, params: }

    let(:bali) { create_region(name: "Bali", slug: "bali", region_type: Region::REGION_TYPES[:admin_area]) }
    let(:north_bali) do
      create_region(
        name: "North Bali",
        slug: "north-bali",
        region_type: Region::REGION_TYPES[:locality],
        parent_id: bali.id
      )
    end
    let(:lombok) { create_region(name: "Lombok", slug: "lombok", region_type: Region::REGION_TYPES[:admin_area]) }
    let!(:sekumpul) do
      create(
        :waterfall,
        height_meters: 80.0,
        plunge_pool: true,
        approach_difficulty: "moderate",
        spot: create(
          :spot,
          :published,
          region: north_bali,
          name: "Sekumpul Waterfall"
        )
      )
    end
    let!(:gitgit) do
      create(
        :waterfall,
        height_meters: 35.0,
        plunge_pool: false,
        approach_difficulty: "easy",
        spot: create(
          :spot,
          :published,
          region: north_bali,
          name: "Gitgit Waterfall"
        )
      )
    end
    let!(:outside_region) do
      create(
        :waterfall,
        height_meters: 75.0,
        plunge_pool: true,
        approach_difficulty: "moderate",
        spot: create(
          :spot,
          :published,
          region: lombok,
          name: "Sendang Gile"
        )
      )
    end
    let!(:draft_match) do
      create(
        :waterfall,
        height_meters: 95.0,
        plunge_pool: true,
        approach_difficulty: "moderate",
        spot: create(
          :spot,
          region: north_bali,
          name: "Hidden Draft Falls"
        )
      )
    end
    let(:params) do
      {
        region_public_id: north_bali.public_id,
        min_height_meters: "50",
        plunge_pool: "true",
        approach_difficulty: "moderate"
      }
    end

    it "renders only matching published waterfalls for the server-rendered catalog" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sekumpul Waterfall")
      expect(response.body).not_to include("Gitgit Waterfall")
      expect(response.body).not_to include("Sendang Gile")
      expect(response.body).not_to include("Hidden Draft Falls")
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
    let(:slugged_public_id) { "#{waterfall.spot.public_id}--wrong-slug" }

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
      let(:slugged_public_id) { "missing--wrong-slug" }

      it "returns not found" do
        perform_request

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /waterfalls/map_data" do
    subject(:perform_request) { get map_data_waterfalls_path, params:, as: :json }

    let(:bali) { create_region(name: "Bali", slug: "bali", region_type: Region::REGION_TYPES[:admin_area]) }
    let(:north_bali) do
      create_region(
        name: "North Bali",
        slug: "north-bali",
        region_type: Region::REGION_TYPES[:locality],
        parent_id: bali.id
      )
    end
    let(:lombok) { create_region(name: "Lombok", slug: "lombok", region_type: Region::REGION_TYPES[:admin_area]) }
    let!(:sekumpul) do
      create(
        :waterfall,
        height_meters: 80.0,
        plunge_pool: true,
        approach_difficulty: "moderate",
        spot: create(
          :spot,
          :published,
          region: north_bali,
          name: "Sekumpul Waterfall",
          summary: "Twin cascades in North Bali.",
          location: point(115.1806, -8.1694)
        )
      )
    end
    let!(:gitgit) do
      create(
        :waterfall,
        height_meters: 35.0,
        plunge_pool: false,
        approach_difficulty: "easy",
        spot: create(
          :spot,
          :published,
          region: north_bali,
          name: "Gitgit Waterfall",
          location: point(115.1415, -8.1883)
        )
      )
    end
    let!(:outside_bounds) do
      create(
        :waterfall,
        height_meters: 45.0,
        plunge_pool: true,
        approach_difficulty: "hard",
        spot: create(
          :spot,
          :published,
          region: lombok,
          name: "Sendang Gile",
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
    let(:params) do
      {
        west: "115.0",
        south: "-8.3",
        east: "115.3",
        north: "-8.0"
      }
    end

    it "returns published waterfalls within bounds as feature collection" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("type")).to eq("FeatureCollection")
      public_ids = json_response.fetch("features").map { |feature| feature.dig("properties", "public_id") }

      expect(public_ids).to include(sekumpul.spot.public_id, gitgit.spot.public_id)
      expect(public_ids).not_to include(outside_bounds.spot.public_id, draft_waterfall.spot.public_id)
    end

    it "applies region and plunge pool filters" do
      params.merge!(region_public_id: north_bali.public_id, plunge_pool: "true")

      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("features").map { |feature| feature.dig("properties", "name") }).to eq([ "Sekumpul Waterfall" ])
    end

    it "returns the feature geometry used by the explore UI" do
      params.merge!(region_public_id: north_bali.public_id, plunge_pool: "true")

      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("features").size).to eq(1)

      feature = json_response.fetch("features").first

      expect(feature).to include(
        "type" => "Feature",
        "geometry" => {
          "type" => "Point",
          "coordinates" => [ 115.1806, -8.1694 ]
        }
      )
    end

    it "returns the feature identity properties used by the explore UI" do
      params.merge!(region_public_id: north_bali.public_id, plunge_pool: "true")
      perform_request
      expect(response).to have_http_status(:ok)
      properties = json_response.fetch("features").sole.fetch("properties")

      expect(properties).to include(
        "public_id" => sekumpul.spot.public_id,
        "path" => waterfall_path(sekumpul.spot),
        "name" => "Sekumpul Waterfall",
        "summary" => "Twin cascades in North Bali.",
        "region_name" => "North Bali",
        "approach_difficulty" => "moderate"
      )
    end

    it "returns the feature label properties used by the explore UI" do
      params.merge!(region_public_id: north_bali.public_id, plunge_pool: "true")
      perform_request
      expect(response).to have_http_status(:ok)
      properties = json_response.fetch("features").sole.fetch("properties")

      expect(properties).to include(
        "height_label" => I18n.t("waterfalls.shared.height", value: sekumpul.height_meters),
        "plunge_pool" => true,
        "plunge_pool_label" => I18n.t("waterfalls.index.filters.plunge_pool_yes")
      )
    end

    context "when the bounds are malformed" do
      let(:params) { { west: "abc", south: "-8.3", east: "115.3", north: "-8.0" } }

      it "returns unprocessable entity" do
        perform_request

        expect(response).to have_http_status(422)
      end
    end

    context "when the bounds are incomplete" do
      let(:params) { { west: "115.0", south: "-8.3", east: "115.3" } }

      it "returns unprocessable entity" do
        perform_request

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the bounds are missing" do
      let(:params) { { region_public_id: north_bali.public_id } }

      it "returns unprocessable entity" do
        perform_request

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  def content_security_policy_directives
    response
      .headers
      .fetch("Content-Security-Policy")
      .split(";")
      .map(&:strip)
      .reject(&:empty?)
      .to_h do |directive|
        name, *values = directive.split(" ")
        [ name, values ]
      end
  end

  def create_region(name:, slug:, region_type:, parent_id: nil)
    result = Regions::CreateRegion.call(
      input: {
        name:,
        slug:,
        region_type:,
        parent_id:
      }
    )

    result.value![:region]
  end

  def point(longitude, latitude)
    RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude)
  end
end
