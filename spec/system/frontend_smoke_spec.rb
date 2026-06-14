# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Frontend smoke", type: :system do
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

  it "renders and updates the React page through Rails" do
    visit frontend_smoke_path

    expect(page).to have_css("h1", text: I18n.t("frontend.smoke.title"))

    click_button I18n.t("frontend.smoke.interaction")

    expect(page).to have_css("[role='status']", text: I18n.t("frontend.smoke.interaction"))
  end
end
