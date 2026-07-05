# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin dashboard", type: :request do
  def sign_in_as(user_identity)
    post session_path, params: {
      session: {
        email: user_identity.email,
        password: "Password123!"
      }
    }
  end

  describe "GET /admin" do
    it "redirects guests to sign in" do
      get admin_root_path

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication"))
    end

    it "redirects members to the explore homepage" do
      sign_in_as(create(:user_identity))

      get admin_root_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("admin.authorization.required"))
    end

    it "renders the empty admin dashboard for admins" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      sign_in_as(admin_identity)

      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(inertia).to be_inertia_response
      expect(inertia).to render_component("Admin/Dashboard/Index")
      expect(inertia.props.keys).to contain_exactly("copy", "errors", "navigation", "shell")
    end

    it "sends the least-data admin dashboard shell contract" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      sign_in_as(admin_identity)

      get admin_root_path

      expect(inertia.props.dig("navigation", "sections")).to eq(admin_navigation_sections(current: "dashboard").as_json)
      expect(inertia.props.dig("shell", "urls", "admin")).to eq(admin_root_path)
      expect(inertia.props.fetch("errors")).to eq({})
      expect(nested_keys(inertia.props)).not_to include(*admin_sensitive_prop_keys)
    end
  end

  def admin_navigation_sections(current:, locale: I18n.locale)
    [
      {
        key: "primary",
        items: [
          {
            key: "dashboard",
            icon: "dashboard",
            label: I18n.t("admin.navigation.dashboard", locale:),
            url: admin_root_path,
            current: current == "dashboard"
          },
          {
            key: "service_actions",
            icon: "wrench",
            label: I18n.t("admin.navigation.service_actions", locale:),
            url: admin_service_actions_path,
            current: current == "service_actions"
          }
        ]
      },
      {
        key: "models",
        label: I18n.t("admin.navigation.models", locale:),
        items: [
          {
            key: "users",
            icon: "users",
            label: I18n.t("admin.navigation.users", locale:),
            url: admin_users_path,
            current: current == "users"
          },
          {
            key: "regions",
            icon: "regions",
            label: I18n.t("admin.navigation.regions", locale:),
            url: admin_regions_path,
            current: current == "regions"
          }
        ]
      }
    ]
  end

  def admin_sensitive_prop_keys
    %w[
      credential
      credentials
      current_user
      identity
      password
      policy
      primary_email
      reset_token
      role
      session
      status
      token
      user
    ]
  end
end
