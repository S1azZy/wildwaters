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
    use_headless_chrome!
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
    user_identity = sign_in_with_unique_identity("waterfall-detail")

    expect(page).to have_current_path(root_path)
    expect_authenticated_account_menu

    visit waterfall_path(waterfall.spot)

    expect_authenticated_account_menu
    expect(page).not_to have_link(I18n.t("layouts.header.sign_in"), href: new_session_path)
    expect(page).not_to have_text(user_identity.email)
  end

  it "crosses the legacy and Inertia runtime boundary with full document visits" do
    page.current_window.resize_to(1_280, 900)

    visit waterfalls_path
    expect_explore_inertia_runtime
    open_waterfall_from_explore

    expect(page).to have_current_path(waterfall_path(waterfall.spot))
    expect_inertia_runtime

    click_link I18n.t("waterfalls.show.back")

    expect(page).to have_current_path(waterfalls_path)
    expect_explore_inertia_runtime
  end

  def open_waterfall_from_explore
    click_button I18n.t("waterfalls.index.rail_toggle")
    within("[data-explore-map-target='list'] article[data-public-id='#{waterfall.spot.public_id}']") do
      click_link "Sekumpul Waterfall"
    end
  end

  def expect_inertia_runtime
    expect(page).to have_css("[data-waterfall-detail='#{waterfall.spot.public_id}']", visible: false)
    expect(page).to have_css("script[type='module'][src*='application']", visible: false)
  end

  def expect_explore_inertia_runtime
    expect(page).to have_css("#explore-home", visible: false)
    expect(page).to have_css("script[type='module'][src*='application']", visible: false)
  end

  def sign_in_with_unique_identity(prefix)
    email = "#{prefix}-#{SecureRandom.hex(4)}@example.com"
    user_identity = create(:user_identity, user: create(:user, primary_email: email), email:)

    visit new_session_path
    fill_in I18n.t("auth.fields.email"), with: user_identity.email
    fill_in I18n.t("auth.fields.password"), with: "Password123!"
    click_button I18n.t("auth.sessions.new.submit")

    user_identity
  end

  def expect_authenticated_account_menu
    account_menu = find("button[aria-label='#{I18n.t("layouts.header.account_menu")}']")
    account_menu.click
    expect(page).to have_css("[role='menuitem'][aria-disabled='true']", text: I18n.t("layouts.header.profile"))
    expect(page).to have_css("[role='menuitem']", text: I18n.t("layouts.header.sign_out"))
    expect(page).not_to have_css("[role='menuitem']", text: I18n.t("layouts.header.admin"))
    find("body").send_keys(:escape)
  end
end
