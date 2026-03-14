require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "GET /dashboard" do
    subject(:perform_request) { get dashboard_path }

    it "redirects unauthenticated users to sign in" do
      perform_request

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication"))
    end
  end

  describe "POST /registration" do
    subject(:perform_request) { post registration_path, params: registration_params }

    let(:registration_params) do
      {
        registration: {
          email: "new@example.com",
          password: "Password123!",
          password_confirmation:,
          locale:
        }
      }
    end
    let(:password_confirmation) { "Password123!" }
    let(:locale) { "ru" }

    it "registers the user, creates a session, and redirects to the dashboard" do
      expect { perform_request }.to change(User, :count).by(1)
        .and change(UserIdentity, :count).by(1)
        .and change(Session, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    context "when registration is invalid" do
      let(:password_confirmation) { "Mismatch123!" }
      let(:locale) { "en" }

      it "renders the form with an error status" do
        expect { perform_request }.not_to change { [ User.count, UserIdentity.count ] }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST /session" do
    subject(:perform_request) { post session_path, params: session_params }

    let(:session_params) do
      {
        session: {
          email:,
          password:
        }
      }
    end
    let(:email) { " USER@example.com " }
    let(:password) { "Password123!" }
    let(:user_identity) { create(:user_identity, email: "user@example.com") }

    before do
      user_identity
    end

    it "signs in and redirects to the dashboard" do
      expect { perform_request }.to change(Session, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    context "when credentials are invalid" do
      let(:email) { "user@example.com" }
      let(:password) { "wrong-password" }

      it "shows a generic failure message" do
        expect { perform_request }.not_to change(Session, :count)
        expect(response.body).to include(I18n.t("auth.sessions.create.failure"))
      end
    end
  end

  describe "DELETE /session" do
    subject(:perform_request) { delete session_path }

    let(:user_identity) { create(:user_identity, email: "user@example.com") }

    before do
      user_identity
      post session_path, params: {
        session: {
          email: "user@example.com",
          password: "Password123!"
        }
      }
    end

    it "revokes the current session and redirects to sign in" do
      expect { perform_request }.to change { Session.order(:created_at).last.reload.revoked_at }.from(nil)
      expect(response).to redirect_to(new_session_path)
    end

    it "stops authenticating revoked sessions" do
      session_record = Session.order(:created_at).last
      session_record.revoke!

      get dashboard_path

      expect(response).to redirect_to(new_session_path)
    end
  end
end
