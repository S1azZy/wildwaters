# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication screens", type: :system do
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

  it "signs in through the migrated Inertia screen and reaches legacy explore", :aggregate_failures do
    user_identity = create(:user_identity, email: "user@example.com")

    visit new_session_path
    expect_inertia_auth_page("session")

    fill_in I18n.t("auth.fields.email"), with: user_identity.email
    fill_in I18n.t("auth.fields.password"), with: "Password123!"
    click_button I18n.t("auth.sessions.new.submit")

    expect(page).to have_current_path(root_path)
    expect(Session.active.where(user: user_identity.user).count).to eq(1)
    expect_legacy_runtime
  end

  it "renders safe sign-in errors through the migrated screen", :aggregate_failures do
    create(:user_identity, email: "user@example.com")

    visit new_session_path
    fill_in I18n.t("auth.fields.email"), with: "user@example.com"
    fill_in I18n.t("auth.fields.password"), with: "wrong-password"
    click_button I18n.t("auth.sessions.new.submit")

    expect(page).to have_current_path(session_path)
    expect(page).to have_css("[data-auth-page='session']")
    expect(page).to have_text(I18n.t("auth.sessions.create.failure"))
    expect(Session.count).to eq(0)
  end

  it "registers through the migrated Inertia screen", :aggregate_failures do
    visit new_registration_path
    expect_inertia_auth_page("registration")

    fill_in I18n.t("auth.fields.email"), with: "new@example.com"
    fill_in I18n.t("auth.fields.password"), with: "Password123!"
    fill_in I18n.t("auth.fields.password_confirmation"), with: "Password123!"
    select I18n.t("auth.locales.en"), from: I18n.t("auth.fields.locale")
    click_button I18n.t("auth.registrations.new.submit")

    expect(page).to have_current_path(dashboard_path)
    expect(page).to have_css("[data-dashboard-page]")
    expect(UserIdentity.exists?(email: "new@example.com")).to be(true)
  end

  it "runs the migrated password reset request and edit forms", :aggregate_failures do
    user_identity = create(:user_identity, email: "reset@example.com")

    request_password_reset_for(user_identity)
    token = prepare_reset_token_for(user_identity)
    submit_new_password(token)

    expect(page).to have_current_path(new_session_path)
    expect(page).to have_text(I18n.t("auth.password_resets.update.success"))
    expect(Session.active.where(user: user_identity.user).count).to eq(0)
  end

  def expect_inertia_auth_page(page_name)
    expect(page).to have_css("[data-auth-page='#{page_name}']")
    expect_inertia_runtime
  end

  def request_password_reset_for(user_identity)
    visit new_password_reset_path
    expect_inertia_auth_page("password-reset-new")

    fill_in I18n.t("auth.fields.email"), with: user_identity.email
    click_button I18n.t("auth.password_resets.new.submit")

    expect(page).to have_current_path(new_session_path)
    expect(page).to have_text(I18n.t("auth.password_resets.create.success"))
  end

  def prepare_reset_token_for(user_identity)
    token = "reset-token"
    user_identity.update!(
      password_reset_token_digest: UserIdentity.digest_token(token),
      password_reset_sent_at: Time.current,
    )
    create(:session, user: user_identity.user, user_identity:)
    token
  end

  def submit_new_password(token)
    visit password_reset_token_path(token)
    expect_inertia_auth_page("password-reset-edit")

    fill_in I18n.t("auth.fields.password"), with: "NewPassword123!"
    fill_in I18n.t("auth.fields.password_confirmation"), with: "NewPassword123!"
    click_button I18n.t("auth.password_resets.edit.submit")
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
