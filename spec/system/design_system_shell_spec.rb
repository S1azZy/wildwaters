require "rails_helper"

RSpec.describe "Design system shell", type: :system do
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

  it "renders the shared guest header shell" do
    visit root_path

    expect(page).to have_css("[data-ui='site-header']")
    expect(page).to have_css("[data-ui='site-header-brand']", text: I18n.t("layouts.header.brand_name"))
    expect(page).to have_css("[data-ui='site-header-tagline']", text: /#{Regexp.escape(I18n.t("layouts.header.brand_tagline"))}/i)
  end

  it "renders the shared guest header navigation items" do
    visit root_path

    expect(page).to have_css("[data-ui='site-header-nav-item']", text: I18n.t("layouts.header.explore"))
    expect(page).not_to have_css("[data-ui='site-header-nav-item']", text: I18n.t("layouts.header.map"))
    expect(page).not_to have_css("[data-ui='site-header-nav-item']", text: I18n.t("layouts.header.activity"))
    expect(page).not_to have_css("[data-ui='site-header-nav-item']", text: I18n.t("layouts.header.profile"))
  end

  it "renders the shared guest header navigation and actions" do
    visit root_path

    expect(page).to have_css("[data-ui='site-header-primary-nav']")
    expect(page).to have_css("[data-ui='site-header-actions']")
    expect(page).to have_link(I18n.t("layouts.header.sign_in"))
    expect(page).not_to have_link(I18n.t("layouts.header.create_account"))
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

  it "renders the auth shell on the sign-in page without a footer" do
    visit new_session_path

    expect(page).to have_css("[data-ui='auth-shell'][data-variant='session']")
    expect(page).to have_css("[data-ui='auth-card']")
    expect_inertia_runtime
    expect(page).not_to have_css("[data-ui='auth-footer']")
  end

  it "renders the auth shell on the sign-up page without a footer" do
    visit new_registration_path

    expect(page).to have_css("[data-ui='auth-shell'][data-variant='registration']")
    expect(page).to have_css("[data-ui='auth-card']")
    expect_inertia_runtime
    expect(page).not_to have_css("[data-ui='auth-footer']")
  end

  it "renders the auth shell on the recovery page without a footer" do
    visit new_password_reset_path

    expect(page).to have_css("[data-ui='auth-shell'][data-variant='recovery']")
    expect(page).to have_css("[data-ui='auth-card']")
    expect_inertia_runtime
    expect(page).not_to have_css("[data-ui='auth-footer']")
  end

  it "shows the profile action in the header after a successful sign-in" do
    create(:user_identity, email: "user@example.com")

    visit new_session_path
    fill_in I18n.t("auth.fields.email"), with: "user@example.com"
    fill_in I18n.t("auth.fields.password"), with: "Password123!"
    click_button I18n.t("auth.sessions.new.submit")

    expect(page).to have_current_path(root_path)
    expect(page).to have_link(I18n.t("layouts.header.profile"), href: dashboard_path)
    expect(page).not_to have_link(I18n.t("layouts.header.sign_in"), href: new_session_path)
  end

  def expect_inertia_runtime
    expect(page).not_to have_css("script[type='importmap']", visible: false)
    expect(page).to have_css("script[type='module']", visible: false)
  end
end
