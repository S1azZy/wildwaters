# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin jobs", type: :request do
  let(:application_routes) { Rails.application.routes.url_helpers }

  def sign_in_as(user_identity)
    post session_path, params: {
      session: {
        email: user_identity.email,
        password: "Password123!"
      }
    }
  end

  describe "GET /admin/jobs" do
    subject(:perform_request) { get "/admin/jobs" }

    it "redirects guests to sign in" do
      perform_request

      expect(response).to redirect_to(application_routes.new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication"))
    end

    context "when the user is authenticated but not an admin" do
      let(:user_identity) { create(:user_identity) }

      before do
        sign_in_as(user_identity)
      end

      it "redirects to the homepage" do
        perform_request

        expect(response).to redirect_to(application_routes.root_path)
        expect(flash[:alert]).to eq(I18n.t("admin.authorization.required"))
      end
    end

    context "when the user is an admin" do
      let(:user) { create(:user, role: "admin") }
      let(:user_identity) { create(:user_identity, user:, email: "admin@example.com") }

      before do
        sign_in_as(user_identity)
      end

      it "renders the jobs dashboard" do
        perform_request

        expect(response).to have_http_status(:ok)
      end

      it "is not shadowed by the application-owned admin Inertia page" do
        perform_request

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/html")
        expect(response.body).not_to include("Admin/ServiceActions/Index")
      end
    end
  end
end
