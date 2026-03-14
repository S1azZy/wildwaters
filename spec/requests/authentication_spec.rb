require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "GET /dashboard" do
    it "redirects unauthenticated users to sign in" do
      get dashboard_path

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication"))
    end
  end

  describe "POST /registration" do
    it "registers the user, creates a session, and redirects to the dashboard" do
      expect { register_user(password_confirmation: "Password123!", locale: "ru") }.to change(User, :count).by(1)
        .and change(UserIdentity, :count).by(1)
        .and change(Session, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    it "renders errors when registration is invalid" do
      expect { register_user(password_confirmation: "Mismatch123!") }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /session" do
    let(:user_identity) { create(:user_identity, email: "user@example.com") }

    before do
      user_identity
    end

    it "signs in and redirects to the dashboard" do
      expect { sign_in_user(email: " USER@example.com ") }.to change(Session, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    it "shows a generic failure message when credentials are invalid" do
      expect { sign_in_user(password: "wrong-password") }.not_to change(Session, :count)

      expect(response.body).to include(I18n.t("auth.sessions.create.failure"))
    end
  end

  describe "DELETE /session" do
    let(:user_identity) { create(:user_identity, email: "user@example.com") }

    before do
      user_identity
      sign_in_user
    end

    it "revokes the current session and redirects to sign in" do
      delete session_path

      expect(response).to redirect_to(new_session_path)
      expect(Session.order(:created_at).last).to be_revoked
    end

    it "stops authenticating revoked sessions" do
      session_record = Session.order(:created_at).last
      session_record.revoke!

      get dashboard_path

      expect(response).to redirect_to(new_session_path)
    end
  end

  def register_user(password_confirmation:, locale: "en")
    post registration_path, params: {
      registration: {
        email: "new@example.com",
        password: "Password123!",
        password_confirmation:,
        locale:
      }
    }
  end

  def sign_in_user(email: "user@example.com", password: "Password123!")
    post session_path, params: {
      session: {
        email:,
        password:
      }
    }
  end
end
