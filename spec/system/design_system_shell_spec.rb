require "rails_helper"

RSpec.describe "Design system shell", type: :system do
  it "renders the shared guest header shell" do
    visit root_path

    expect(page).to have_css("[data-ui='site-header']")
    expect(page).to have_css("[data-ui='site-header-brand']", text: I18n.t("layouts.header.brand_name"))
    expect(page).to have_css("[data-ui='site-header-tagline']", text: I18n.t("layouts.header.brand_tagline"))
    expect(page).to have_link(I18n.t("layouts.header.sign_in"))
    expect(page).to have_link(I18n.t("layouts.header.create_account"))
  end
end
