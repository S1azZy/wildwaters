require "rails_helper"

RSpec.describe Ui::SiteHeaderComponent, type: :component do
  let(:labels) do
    {
      brand_name: "Wild Waters",
      brand_tagline: "Swim the World",
      explore: "Explore",
      info: "Info",
      dashboard: "Dashboard",
      sign_in: "Sign in",
      create_account: "Create account",
      sign_out: "Sign out"
    }
  end
  let(:base_arguments) do
    {
      labels:,
      explore_path: "/",
      info_path: "/#about",
      dashboard_path: "/dashboard",
      sign_in_path: "/session/new",
      registration_path: "/registration/new",
      session_path: "/session"
    }
  end

  def build_component(**overrides)
    described_class.new(**base_arguments.merge(overrides))
  end

  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end
  end

  describe "#navigation_items" do
    it "returns the primary navigation with active state for the current path" do
      component = build_component(current_path: "/", authenticated: false)

      expect(component.navigation_items).to eq(
        [
          { key: :explore, label: "Explore", path: "/", current: true },
          { key: :info, label: "Info", path: "/#about", current: false }
        ]
      )
    end

    it "keeps explore active for browse urls with query parameters" do
      component = build_component(current_path: "/?region_public_id=bali", authenticated: false)

      expect(component.navigation_items).to eq(
        [
          { key: :explore, label: "Explore", path: "/", current: true },
          { key: :info, label: "Info", path: "/#about", current: false }
        ]
      )
    end

    it "never marks the about anchor as current on the server" do
      component = build_component(current_path: "/#about", authenticated: false)

      expect(component.navigation_items).to eq(
        [
          { key: :explore, label: "Explore", path: "/", current: false },
          { key: :info, label: "Info", path: "/#about", current: false }
        ]
      )
    end
  end

  describe "#session_actions" do
    it "returns guest actions when the user is not authenticated" do
      component = build_component(current_path: "/", authenticated: false)

      expect(component.session_actions).to eq(
        [
          { key: :sign_in, label: "Sign in", path: "/session/new", method: nil },
          { key: :create_account, label: "Create account", path: "/registration/new", method: nil }
        ]
      )
    end

    it "returns authenticated actions when the user is signed in" do
      component = build_component(current_path: "/dashboard", authenticated: true)

      expect(component.session_actions).to eq(
        [
          { key: :dashboard, label: "Dashboard", path: "/dashboard", method: nil },
          { key: :sign_out, label: "Sign out", path: "/session", method: :delete }
        ]
      )
    end
  end

  describe "rendering" do
    it "renders the brand and primary navigation" do
      render_inline(build_component(current_path: "/", authenticated: false))

      expect(page).to have_css("[data-ui='site-header']")
      expect(page).to have_css("[data-ui='site-header-brand']", text: "Wild Waters")
      expect(page).to have_css("[data-ui='site-header-primary-nav']")
      expect(page).to have_link("Explore", href: "/")
      expect(page).to have_link("Info", href: "/#about")
    end

    it "renders the guest action cluster" do
      render_inline(build_component(current_path: "/", authenticated: false))

      expect(page).to have_css("[data-ui='site-header-actions']")
      expect(page).to have_link("Sign in", href: "/session/new")
      expect(page).to have_link("Create account", href: "/registration/new")
    end

    it "renders authenticated actions in the utility cluster" do
      render_inline(build_component(current_path: "/dashboard", authenticated: true))

      expect(page).to have_css("[data-ui='site-header-actions']")
      expect(page).to have_link("Dashboard", href: "/dashboard")
      expect(page).to have_button("Sign out")
    end
  end
end
