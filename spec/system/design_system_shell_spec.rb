require "rails_helper"

RSpec.describe "Design system shell", type: :system do
  before do
    use_headless_chrome!
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

  it "renders the auth shell on the sign-in page" do
    visit new_session_path

    expect(page).to have_css("[data-ui='auth-shell'][data-variant='session']")
    expect(page).to have_css("[data-ui='auth-card']")
    expect_inertia_runtime
  end

  it "renders the auth shell on the sign-up page" do
    visit new_registration_path

    expect(page).to have_css("[data-ui='auth-shell'][data-variant='registration']")
    expect(page).to have_css("[data-ui='auth-card']")
    expect_inertia_runtime
  end

  it "renders the auth shell on the recovery page" do
    visit new_password_reset_path

    expect(page).to have_css("[data-ui='auth-shell'][data-variant='recovery']")
    expect(page).to have_css("[data-ui='auth-card']")
    expect_inertia_runtime
  end

  it "shows the account menu in the header after a successful sign-in" do
    sign_in_with_unique_identity("account-menu")

    expect(page).to have_current_path(root_path)
    account_menu = find("button[aria-label='#{I18n.t("layouts.header.account_menu")}']")
    account_menu.click
    expect(page).to have_css("[role='menuitem'][aria-disabled='true']", text: I18n.t("layouts.header.profile"))
    expect(page).to have_css("[role='menuitem']", text: I18n.t("layouts.header.sign_out"))
    expect(page).not_to have_css("[role='menuitem']", text: I18n.t("layouts.header.admin"))
    expect(page).not_to have_link(I18n.t("layouts.header.sign_in"), href: new_session_path)
  end

  def sign_in_with_unique_identity(prefix)
    email = "#{prefix}-#{SecureRandom.hex(4)}@example.com"
    user_identity = create(:user_identity, user: create(:user, primary_email: email), email:)

    visit new_session_path
    fill_in I18n.t("auth.fields.email"), with: user_identity.email
    fill_in I18n.t("auth.fields.password"), with: "Password123!"
    click_button I18n.t("auth.sessions.new.submit")
  end
end
