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
  let!(:overflow_waterfalls) do
    Array.new(14) do |index|
      create(
        :waterfall,
        height_meters: 20 + index,
        plunge_pool: index.even?,
        approach_difficulty: %w[easy moderate hard].fetch(index % 3),
        spot: create(
          :spot,
          :published,
          name: "Overflow Waterfall #{index + 1}"
        )
      )
    end
  end

  before do
    driven_by(
      :selenium,
      using: :chrome,
      screen_size: [ 1_280, 900 ],
    ) do |browser_options|
      browser_options.binary = "/usr/bin/chromium" if File.executable?("/usr/bin/chromium")
      browser_options.add_argument("--headless=new")
      browser_options.add_argument("--no-sandbox")
      browser_options.add_argument("--disable-dev-shm-usage")
    end

    sekumpul_waterfall
    nungnung_waterfall
    tegenungan_waterfall
    draft_waterfall
    overflow_waterfalls
  end

  it "renders the public header links", :aggregate_failures do
    visit_page

    expect(page).to have_current_path(root_path)
    expect(page).to have_css("[data-ui='site-header-brand']", text: I18n.t("layouts.header.brand_name"))
    expect(page).to have_css("[data-ui='site-header-primary-nav']")
    expect_public_header_navigation
    expect(page).to have_css("[data-ui='site-header-actions']")
    expect(page).to have_link(I18n.t("layouts.header.sign_in"))
    expect(page).not_to have_link(I18n.t("layouts.header.create_account"))
  end

  it "renders the explore page shell" do
    visit_page

    expect(page).to have_css("section#explore-home")
    expect(page).not_to have_css("section#explore-home[data-controller='explore-map']")
    expect(page).to have_css("[data-explore-map-target='canvas']")
    expect(page).to have_css("[data-explore-map-target='list']", visible: false)
    expect(page).to have_css("[data-explore-map-target='resultCount']", visible: false)
    expect_inertia_runtime
  end

  it "renders the map target inside an observable shell" do
    visit_page

    expect(page).to have_css(".explore-map-shell[data-explore-map-target='shell']")
    expect(page).to have_css(".explore-map-shell[data-explore-map-target='shell'] .explore-map-surface > [data-explore-map-target='canvas'][class*='explore-map-canvas'][class*='h-full'][class*='w-full']")
  end

  it "renders a full-bleed map shell under the header" do
    visit_page

    expect(page).to have_css("main.w-full.min-h-0.p-0")
    expect(page).to have_css("section#explore-home.explore-layout-shell")
    expect(page).to have_css(".explore-map-shell.explore-map-shell--full-bleed[data-explore-map-target='shell']")
    expect(page).to have_css(".explore-map-shell--viewport-fit[data-explore-map-target='shell']")
  end

  it "renders a dedicated filter bar directly under the header" do
    visit_page

    expect(page).to have_css(".explore-filter-band")
    expect(page).to have_css(".explore-filter-row[data-desktop-layout='single-row']")
    expect(page).to have_css(".explore-filter-form[data-desktop-wrap='never']")
    expect(page).to have_css(".explore-map-shell--viewport-fit[data-explore-map-target='shell']")
  end

  it "renders the search and filter controls inside the filter bar" do
    visit_page

    expect(page).to have_css(".explore-filter-band [data-explore-map-target='filters']")
    expect(page).to have_css(".explore-filter-band [data-explore-map-target='search']")
    expect(page).not_to have_button(I18n.t("waterfalls.index.filters.apply"))
    expect(page).not_to have_css(".explore-filter-band [data-explore-map-target='resultsToggle']")
  end

  it "renders the basemap style control on top of the map" do
    visit_page

    expect(page).to have_css(".explore-map-toolbar")
    expect(page).to have_css(".explore-map-shell details[data-explore-map-target='styleMenu']")
    expect(page).to have_css(".explore-map-shell summary", text: I18n.t("waterfalls.index.map_styles.menu_label"))
  end

  it "renders custom zoom controls inside the shared map toolbar" do
    visit_page

    expect(page).to have_css(".explore-map-toolbar button[aria-label='Zoom in']")
    expect(page).to have_css(".explore-map-toolbar button[aria-label='Zoom out']")
  end

  it "renders the collapsible explore rail toggle on top of the map" do
    visit_page

    expect(page).to have_css(".explore-map-shell [data-explore-map-target='resultsToggle']", text: I18n.t("waterfalls.index.rail_toggle"))
    expect(page).to have_css(".explore-map-shell [data-explore-map-target='resultsToggle'][aria-expanded='false']")
  end

  it "renders the basemap style options for all supported map views" do
    visit_page

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

  it "exposes the shared card template for refreshed list rendering" do
    visit_page

    expect(page).to have_css("[data-explore-map-target='list'][data-card-class-template]", visible: false)
    expect(page).not_to have_text(I18n.t("waterfalls.index.list_mode"))
  end

  it "renders a collapsible results panel that is hidden by default" do
    visit_page

    expect(page).to have_css(".explore-map-shell [data-explore-map-target='resultsToggle']")
    expect(page).to have_css("[data-explore-map-target='resultsToggle'][aria-expanded='false']")
    expect(page).to have_css("[data-explore-map-target='resultsPanel'].is-collapsed", visible: false)
    expect(page).to have_css("[data-explore-map-target='list'] article[data-public-id='#{sekumpul_waterfall.spot.public_id}']", visible: false)
    expect(page).to have_css("[data-explore-map-target='list'] article[data-public-id='#{nungnung_waterfall.spot.public_id}']", visible: false)
    expect(page).to have_css("[data-explore-map-target='list'] article[data-public-id='#{tegenungan_waterfall.spot.public_id}']", visible: false)
  end

  it "uses the main rail toggle as the only expand and collapse control" do
    visit_page
    list = page.find(:css, "[data-explore-map-target='list']", visible: false)
    rendered_count = list.all(:css, "article[data-public-id]", visible: false).size
    header = page.find(:css, "[data-explore-map-target='resultsHeader']", visible: false)

    expect(page).to have_css(".explore-map-shell [data-explore-map-target='resultsToggle'][aria-controls='explore-results-panel'][aria-expanded='false']")
    expect(page).to have_css("button[data-explore-map-target='resultsToggle']", count: 1)
    expect(header.text(:all)).to include("#{rendered_count} #{I18n.t('waterfalls.index.result_suffix')}")
    expect(header).to have_no_css("button", visible: false)
  end

  it "renders a compact results rail structure with a dedicated scroll region" do
    visit_page
    list = page.find(:css, "[data-explore-map-target='list']", visible: false)
    rendered_count = list.all(:css, "article[data-public-id]", visible: false).size

    expect(page).to have_css("[data-explore-map-target='resultsPanel']", visible: false)
    expect(page).to have_css("[data-explore-map-target='resultsHeader']", visible: false)
    expect(page).to have_css("[data-explore-map-target='resultsScroll']", visible: false)
    expect(page).to have_css("[data-explore-map-target='resultsHeader'] [data-explore-map-target='resultCount']", text: rendered_count.to_s, visible: false)
    expect(page).to have_css("[data-explore-map-target='list'] article[data-public-id='#{overflow_waterfalls.last.spot.public_id}']", visible: false)
  end

  it "keeps a calm rail ending without a visible end label" do
    visit_page
    end_cap = page.find(:css, "[data-explore-map-target='endCap']", visible: false)

    expect(end_cap).to be_present
    expect(page).not_to have_text(I18n.t("waterfalls.index.end_of_list", default: "End of list"))
    expect(page).not_to have_css("[data-explore-map-target='loading']", visible: false)
    expect(page).not_to have_css("[data-explore-map-target='status']", visible: false)
  end

  it "does not render draft waterfalls in the public explore rail" do
    visit_page

    expect(page).not_to have_content("Hidden Draft Falls")
  end

  it "renders a noscript fallback message" do
    visit_page

    expect(page).to have_css("noscript", visible: false)
  end

  it "loads the map library through the migrated Inertia runtime" do
    visit_page

    expect_inertia_runtime
    expect(page).not_to have_css("script[type='importmap']", visible: false)
    expect(page.html).not_to include('"maplibre-gl"')
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
  end

  def expect_inertia_runtime
    expect(page).to have_css("[data-page]", visible: false)
    expect(page).to have_css("script[type='module'][src*='application']", visible: false)
    expect(page).not_to have_css("script[type='importmap']", visible: false)
  end

  def expect_public_header_navigation
    within("[data-ui='site-header']") do
      expect(page).to have_link(I18n.t("layouts.header.explore"))
      expect(page).not_to have_link(I18n.t("layouts.header.map"))
      expect(page).not_to have_link(I18n.t("layouts.header.activity"))
      expect(page).not_to have_link(I18n.t("layouts.header.profile"))
    end
  end
end
