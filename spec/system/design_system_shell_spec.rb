require "rails_helper"

RSpec.describe "Design system shell", type: :system do
  it "renders the shared guest header shell" do
    visit root_path

    expect(page).to have_css("[data-ui='site-header']")
    expect(page).to have_css("[data-ui='site-header-brand']", text: I18n.t("layouts.header.brand_name"))
    expect(page).to have_css("[data-ui='site-header-tagline']", text: I18n.t("layouts.header.brand_tagline"))
  end

  it "renders the shared guest header navigation items" do
    visit root_path

    expect(page).to have_css("[data-ui='site-header-nav-item']", text: I18n.t("layouts.header.explore"))
    expect(page).to have_css("[data-ui='site-header-nav-item']", text: I18n.t("layouts.header.map"))
    expect(page).to have_css("[data-ui='site-header-nav-item']", text: I18n.t("layouts.header.activity"))
    expect(page).to have_css("[data-ui='site-header-nav-item']", text: I18n.t("layouts.header.profile"))
  end

  it "renders the shared guest header navigation and actions" do
    visit root_path

    expect(page).to have_css("[data-ui='site-header-primary-nav']")
    expect(page).to have_css("[data-ui='site-header-actions']")
    expect(page).to have_link(I18n.t("layouts.header.sign_in"))
    expect(page).to have_link(I18n.t("layouts.header.create_account"))
  end

  it "renders layout flash messages through the shared application shell" do
    visit new_password_reset_path

    fill_in I18n.t("auth.fields.email"), with: "missing@example.com"
    click_button I18n.t("auth.password_resets.new.submit")

    expect(page).to have_current_path(new_session_path)
    expect(page).to have_css("[data-ui='flash'][data-tone='notice']")
    expect(page).to have_css(
      "[data-ui='flash-message']",
      text: I18n.t("auth.password_resets.create.success")
    )
  end
end
