# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Waterfall detail", type: :system do
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
        description: "A dramatic jungle waterfall."
      )
    )
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
  end

  it "renders the guest detail page through React at desktop width", :aggregate_failures do
    page.current_window.resize_to(1_280, 900)

    visit waterfall_path(waterfall.spot)

    expect(page).to have_css("h1", text: "Sekumpul Waterfall")
    expect(page).to have_text("Twin cascades in North Bali.")
    expect(page).to have_text("A dramatic jungle waterfall.")
    expect(page).to have_text(I18n.t("waterfalls.show.height_label"))
    expect(page).to have_link(I18n.t("layouts.header.sign_in"), href: new_session_path)
    expect(page).not_to have_link(I18n.t("layouts.header.profile"), href: dashboard_path)
    expect(page).to have_title("Sekumpul Waterfall")
  end

  it "renders the responsive guest detail page at mobile width" do
    page.current_window.resize_to(390, 844)

    visit waterfall_path(waterfall.spot)

    expect(page).to have_css("[data-waterfall-detail='#{waterfall.spot.public_id}']")
    expect(page).to have_css("h1", text: "Sekumpul Waterfall")
    expect(page).to have_link(I18n.t("layouts.header.sign_in"), href: new_session_path)
    expect(page).to have_link(I18n.t("waterfalls.show.back"), href: waterfalls_path)
  end

  it "renders the authenticated header state without exposing identity data" do
    page.current_window.resize_to(1_280, 900)
    create(:user_identity, email: "user@example.com")

    visit new_session_path
    fill_in I18n.t("auth.fields.email"), with: "user@example.com"
    fill_in I18n.t("auth.fields.password"), with: "Password123!"
    click_button I18n.t("auth.sessions.new.submit")

    expect(page).to have_current_path(root_path)
    expect(page).to have_link(I18n.t("layouts.header.profile"), href: dashboard_path)

    visit waterfall_path(waterfall.spot)

    expect(page).to have_link(I18n.t("layouts.header.profile"), href: dashboard_path)
    expect(page).not_to have_link(I18n.t("layouts.header.sign_in"), href: new_session_path)
    expect(page).not_to have_text("user@example.com")
  end

  it "crosses the legacy and Inertia runtime boundary with full document visits" do
    page.current_window.resize_to(1_280, 900)

    visit waterfalls_path
    expect_legacy_runtime
    open_waterfall_from_explore

    expect(page).to have_current_path(waterfall_path(waterfall.spot))
    expect_inertia_runtime

    click_link I18n.t("waterfalls.show.back")

    expect(page).to have_current_path(waterfalls_path)
    expect_legacy_runtime
  end

  def open_waterfall_from_explore
    click_button I18n.t("waterfalls.index.rail_toggle")
    within("[data-explore-map-target='list'] article[data-public-id='#{waterfall.spot.public_id}']") do
      click_link "Sekumpul Waterfall"
    end
  end

  def expect_inertia_runtime
    expect(page).to have_css("[data-waterfall-detail='#{waterfall.spot.public_id}']")
    expect(page).not_to have_css("script[type='importmap']", visible: false)
    expect(page).to have_css("script[type='module']", visible: false)
  end

  def expect_legacy_runtime
    expect(page).to have_css("script[type='importmap']", visible: false)
    expect(page).not_to have_css("[data-page]", visible: false)
  end
end
