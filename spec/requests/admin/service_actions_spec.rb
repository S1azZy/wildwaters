# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin service actions", type: :request do
  def sign_in_as(user_identity)
    post session_path, params: {
      session: {
        email: user_identity.email,
        password: "Password123!"
      }
    }
  end

  def service_actions_props(locale: I18n.locale)
    {
      copy: {
        title: I18n.t("admin.service_actions.index.title", locale:),
        heading: I18n.t("admin.service_actions.index.heading", locale:),
        description: I18n.t("admin.service_actions.index.description", locale:),
        toolbarLabel: I18n.t("admin.shell.toolbar_label", locale:),
        placeholderTitle: I18n.t("admin.service_actions.index.placeholder_title", locale:),
        placeholderDescription: I18n.t("admin.service_actions.index.placeholder_description", locale:)
      },
      navigation: {
        sections: admin_navigation_sections(current: "service_actions", locale:)
      },
      urls: {
        serviceActions: admin_service_actions_path
      }
    }
  end

  shared_examples "admin service actions access" do |path_name|
    describe "GET #{path_name}" do
      subject(:perform_request) { get public_send(path_name) }

      it "redirects guests to sign in" do
        perform_request

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication"))
      end

      context "when the user is authenticated but not an admin" do
        let(:user_identity) { create(:user_identity) }

        before do
          sign_in_as(user_identity)
        end

        it "redirects to the explore homepage" do
          perform_request

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq(I18n.t("admin.authorization.required"))
        end
      end

      context "when the user is an admin" do
        let(:user) { create(:user, role: "admin") }
        let(:user_identity) { create(:user_identity, user:, email: "admin@example.com") }

        before do
          sign_in_as(user_identity)
        end

        it "renders the service actions Inertia page" do
          perform_request

          expect(response).to have_http_status(:ok)
          expect(inertia).to be_inertia_response
          expect(inertia).to render_component("Admin/ServiceActions/Index")
          expect(inertia.props.keys).to contain_exactly("copy", "errors", "navigation", "shell", "urls")
          expect(inertia.props.fetch("errors")).to eq({})
        end

        it "sends the least-data admin shell contract" do
          perform_request

          expect(inertia).to have_props(
            service_actions_props.merge(
              shell: expected_shell_props(authenticated: true, admin: true)
            )
          )
        end

        it "does not expose sensitive admin state" do
          perform_request

          expect(nested_keys(inertia.props)).not_to include(*admin_sensitive_prop_keys)
        end

        it "uses the isolated Inertia runtime document" do
          perform_request

          expect_inertia_runtime_document!
        end
      end
    end
  end

  it_behaves_like "admin service actions access", :admin_service_actions_path

  describe "shared shell admin navigation" do
    it "omits the admin URL for authenticated members" do
      user_identity = create(:user_identity)
      sign_in_as(user_identity)

      get root_path

      expect(inertia.props.dig("shell", "urls")).not_to have_key("admin")
      expect(nested_keys(inertia.props.fetch("shell"))).not_to include("role", "user", "current_user")
    end

    it "includes the admin URL for authenticated admins without exposing the raw role" do
      user = create(:user, role: "admin")
      user_identity = create(:user_identity, user:, email: "admin@example.com")
      sign_in_as(user_identity)

      get root_path

      expect(inertia.props.dig("shell", "urls", "admin")).to eq(admin_root_path)
      expect(nested_keys(inertia.props.fetch("shell"))).not_to include("role", "user", "current_user")
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
