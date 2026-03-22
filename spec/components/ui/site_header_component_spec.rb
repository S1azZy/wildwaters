require "rails_helper"

RSpec.describe Ui::SiteHeaderComponent, type: :component do
  let(:labels) do
    {
      brand_name: "Wild Waters",
      brand_tagline: "Swim the World",
      explore: "Explore",
      map: "Map",
      activity: "Activity",
      profile: "Profile",
      notifications: "Notifications",
      settings: "Settings",
      sign_in: "Log in"
    }
  end
  let(:base_arguments) do
    {
      labels:,
      explore_path: "/",
      dashboard_path: "/dashboard",
      map_path: nil,
      activity_path: nil,
      profile_path: "/profile",
      sign_in_path: "/session/new"
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
          { key: :map, label: "Map", path: nil, current: false },
          { key: :activity, label: "Activity", path: nil, current: false },
          { key: :profile, label: "Profile", path: "/profile", current: false }
        ]
      )
    end

    it "keeps explore active for browse urls with query parameters" do
      component = build_component(current_path: "/?region_public_id=bali", authenticated: false)

      expect(component.navigation_items).to eq(
        [
          { key: :explore, label: "Explore", path: "/", current: true },
          { key: :map, label: "Map", path: nil, current: false },
          { key: :activity, label: "Activity", path: nil, current: false },
          { key: :profile, label: "Profile", path: "/profile", current: false }
        ]
      )
    end

    it "marks the profile nav item current when its path matches" do
      component = build_component(current_path: "/profile", authenticated: false)

      expect(component.navigation_items).to eq(
        [
          { key: :explore, label: "Explore", path: "/", current: false },
          { key: :map, label: "Map", path: nil, current: false },
          { key: :activity, label: "Activity", path: nil, current: false },
          { key: :profile, label: "Profile", path: "/profile", current: true }
        ]
      )
    end
  end

  describe "#utility_actions" do
    it "returns guest actions when the user is not authenticated" do
      component = build_component(current_path: "/", authenticated: false)

      expect(component.utility_actions).to eq(
        [
          { key: :sign_in, label: "Log in", path: "/session/new", kind: :button }
        ]
      )
    end

    it "returns authenticated utility controls when the user is signed in" do
      component = build_component(current_path: "/dashboard", authenticated: true, profile_path: "/dashboard")

      expect(component.utility_actions).to eq(
        [
          { key: :notifications, label: "Notifications", path: nil, kind: :icon_button },
          { key: :settings, label: "Settings", path: nil, kind: :icon_button },
          { key: :profile, label: "Profile", path: "/dashboard", kind: :avatar_link }
        ]
      )
    end
  end

  describe "rendering" do
    it "renders the header shell structure" do
      render_inline(build_component(current_path: "/", authenticated: false))

      expect(page).to have_css("[data-ui='site-header']")
      expect(page).to have_css("[data-ui='site-header-frame']")
      expect(page).to have_css(".site-header-surface--compact")
      expect(page).to have_css("[data-ui='site-header-desktop-row']")
    end

    it "renders the trimmed wide frame treatment" do
      render_inline(build_component(current_path: "/", authenticated: false))

      expect(page).to have_css(".site-header-frame--compact")
      expect(page).to have_css(".site-header-frame--trimmed")
      expect(page).to have_css(".site-header-shell--feather")
      expect(page).not_to have_css(".site-header-frame-surface")
    end

    it "renders the brand block inside the header shell" do
      render_inline(build_component(current_path: "/", authenticated: false))

      expect(page).to have_css("[data-ui='site-header-brand']", text: "Wild Waters")
      expect(page).to have_css("[data-ui='site-header-primary-nav']")
    end

    it "renders the expected primary navigation items" do
      render_inline(build_component(current_path: "/", authenticated: false))

      expect(page).to have_link("Explore", href: "/")
      expect(page).to have_css(".site-header-nav-link--prominent", text: "Explore")
      expect(page).to have_css("[data-ui='site-header-nav-item']", text: "Map")
      expect(page).to have_css("[data-ui='site-header-nav-item']", text: "Activity")
      expect(page).to have_css("[data-ui='site-header-nav-item']", text: "Profile")
    end

    it "renders the guest action cluster" do
      render_inline(build_component(current_path: "/", authenticated: false))

      expect(page).to have_css("[data-ui='site-header-actions']")
      expect(page).to have_css("[data-ui='site-header-guest-actions']")
      expect(page).to have_link("Log in", href: "/session/new")
      expect(page).not_to have_link("Create account", href: "/registration/new")
    end

    it "renders authenticated utility icons and avatar" do
      render_inline(build_component(current_path: "/dashboard", authenticated: true, profile_path: "/dashboard"))

      expect(page).to have_css("[data-ui='site-header-actions']")
      expect(page).to have_css("[data-ui='site-header-auth-actions']")
      expect(page).to have_css("[data-ui='icon-button'][aria-label='Notifications']")
      expect(page).to have_css("[data-ui='icon-button'][aria-label='Settings']")
      expect(page).to have_link("Profile", href: "/dashboard")
      expect(page).to have_css("[data-ui='site-header-avatar']")
    end
  end
end
