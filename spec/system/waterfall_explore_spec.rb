require "rails_helper"

RSpec.describe "Waterfall explore", type: :system do
  subject(:visit_page) { visit root_path }

  let!(:sekumpul_waterfall) do
    create(
      :waterfall,
      height_meters: 80.0,
      plunge_pool: true,
      approach_difficulty: "moderate",
      spot: create(
        :spot,
        :published,
        name: "Sekumpul Waterfall"
      )
    )
  end
  let!(:nungnung_waterfall) do
    create(
      :waterfall,
      height_meters: 50.0,
      plunge_pool: false,
      approach_difficulty: "easy",
      spot: create(
        :spot,
        :published,
        name: "Nungnung Waterfall"
      )
    )
  end
  let!(:tegenungan_waterfall) do
    create(
      :waterfall,
      height_meters: 18.0,
      plunge_pool: true,
      approach_difficulty: "hard",
      spot: create(
        :spot,
        :published,
        name: "Tegenungan Waterfall"
      )
    )
  end
  let!(:draft_waterfall) do
    create(
      :waterfall,
      spot: create(
        :spot,
        name: "Hidden Draft Falls"
      )
    )
  end

  before do
    sekumpul_waterfall
    nungnung_waterfall
    tegenungan_waterfall
    draft_waterfall
  end

  it "renders the public header links" do
    visit_page

    expect(page).to have_current_path(root_path)
    expect(page).to have_link("WW")
    expect(page).to have_link(I18n.t("layouts.header.sign_in"))
    expect(page).to have_link(I18n.t("layouts.header.create_account"))
  end

  it "renders the explore page shell" do
    visit_page

    expect(page).to have_css("section#explore-home[data-controller='explore-map']")
    expect(page).to have_css("[data-explore-map-target='canvas']")
    expect(page).to have_css("[data-explore-map-target='list']")
    expect(page).to have_css("[data-explore-map-target='resultCount']")
  end

  it "renders the map target inside an observable shell" do
    visit_page

    expect(page).to have_css(".explore-map-shell[data-explore-map-target='shell']")
    expect(page).to have_css(".explore-map-shell[data-explore-map-target='shell'] .explore-map-surface > [data-explore-map-target='canvas'][class*='explore-map-canvas'][class*='h-full'][class*='w-full']")
  end

  it "renders the basemap style dropdown" do
    visit_page

    expect(page).to have_css("summary", text: I18n.t("waterfalls.index.map_styles.menu_label"))
    expect(page).to have_css("details[data-explore-map-target='styleMenu']")
    expect(page).to have_css("[data-explore-map-target='styleButton'][data-style-id='liberty']", visible: false)
    expect(page).to have_css("[data-explore-map-target='styleButton'][data-style-id='bright']", visible: false)
    expect(page).to have_css("[data-explore-map-target='styleButton'][data-style-id='positron']", visible: false)
    expect(page).to have_css("[data-explore-map-target='styleButton'][data-style-id='outdoors']", visible: false)
  end

  it "renders the textual filter inputs" do
    visit_page

    expect(page).to have_field("explore_search")
    expect(page).to have_select("region_public_id")
    expect(page).to have_field("min_height_meters")
  end

  it "renders the select filter controls" do
    visit_page

    expect(page).to have_select("plunge_pool")
    expect(page).to have_select("approach_difficulty")
    expect(page).to have_css("form[action='#{waterfalls_path}'][method='get']")
  end

  it "renders published waterfalls in the list rail" do
    visit_page

    expect(page).to have_css("[data-explore-map-target='list'] article[data-public-id='#{sekumpul_waterfall.spot.public_id}']")
    expect(page).to have_css("[data-explore-map-target='list'] article[data-public-id='#{nungnung_waterfall.spot.public_id}']")
    expect(page).to have_css("[data-explore-map-target='list'] article[data-public-id='#{tegenungan_waterfall.spot.public_id}']")
    expect(page).to have_content("Sekumpul Waterfall")
    expect(page).to have_content("Nungnung Waterfall")
    expect(page).to have_content("Tegenungan Waterfall")
  end

  it "does not render draft waterfalls in the public explore rail" do
    visit_page

    expect(page).not_to have_content("Hidden Draft Falls")
  end

  it "renders a noscript fallback message" do
    visit_page

    expect(page).to have_css("noscript", text: I18n.t("waterfalls.index.no_javascript"), visible: false)
  end

  it "loads the map library through importmap before the explore controller bootstraps" do
    visit_page

    expect(page).to have_css("script[type='importmap']", visible: false)
    expect(page.html).to include('"maplibre-gl"')
    expect(page.html).to include("/assets/maplibre-gl")
  end

  it "loads maplibre assets locally without remote CDN tags" do
    visit_page

    expect(page).not_to have_css("script[src*='unpkg.com/maplibre-gl']", visible: false)
    expect(page).not_to have_css("link[href*='unpkg.com/maplibre-gl']", visible: false)
    expect(page).to have_css("link[href*='/assets/maplibre-gl']", visible: false)
  end

  it "pins the published maplibre asset version locally" do
    visit_page

    expect(page.html).to include("/assets/maplibre-gl")
    expect(page.html).not_to include("maplibre-gl@5.20.2/dist/maplibre-gl.js")
    expect(page.html).not_to include("maplibre-gl@5.20.2/dist/maplibre-gl.css")
  end
end
