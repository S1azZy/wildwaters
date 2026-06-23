# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  let!(:user_identity) { create(:user_identity, email: "user@example.com") }

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

  it "renders through Inertia and signs out through the Rails session endpoint", :aggregate_failures do
    sign_in
    session_record = Session.order(:created_at).last

    visit dashboard_path
    expect_dashboard_page

    click_button I18n.t("dashboard.show.sign_out", locale: :en)

    expect_signed_out(session_record)
  end

  def sign_in
    visit new_session_path
    fill_in I18n.t("auth.fields.email"), with: user_identity.email
    fill_in I18n.t("auth.fields.password"), with: "Password123!"
    click_button I18n.t("auth.sessions.new.submit")

    expect(page).to have_current_path(root_path)
  end

  def expect_dashboard_page
    expect(page).to have_css("[data-dashboard-page]")
    expect(page).to have_css("h1", text: I18n.t("dashboard.show.heading", locale: :en))
    expect(page).to have_text(I18n.t("dashboard.show.signed_in_as", locale: :en, email: user_identity.user.primary_email))
    expect_inertia_runtime
  end

  def expect_signed_out(session_record)
    expect(page).to have_current_path(new_session_path)
    expect(page).to have_text(I18n.t("auth.sessions.destroy.success", locale: :en))
    expect(session_record.reload.revoked_at).to be_present
    expect_legacy_runtime
  end

  def expect_inertia_runtime
    expect(page).not_to have_css("script[type='importmap']", visible: false)
    expect(page).to have_css("script[type='module']", visible: false)
  end

  def expect_legacy_runtime
    expect(page).to have_css("script[type='importmap']", visible: false)
    expect(page).not_to have_css("[data-page]", visible: false)
  end
end
