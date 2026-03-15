require "rails_helper"

RSpec.describe "Password resets", type: :request do
  describe "GET /password-reset/new" do
    subject(:perform_request) { get new_password_reset_path }

    it "renders the reset request form" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("auth.password_resets.new.heading"))
    end
  end

  describe "POST /password-reset" do
    subject(:perform_request) { post password_reset_path, params: password_reset_params }

    let(:password_reset_params) do
      {
        password_reset: {
          email:
        }
      }
    end

    context "when the email exists" do
      let(:email) { user_identity.email }
      let!(:user_identity) { create(:user_identity, email: "user@example.com") }

      it "redirects with a generic success message" do
        perform_request

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t("auth.password_resets.create.success"))
      end

      it "delivers the reset email" do
        expect { perform_request }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end

    context "when the email does not exist" do
      let(:email) { "missing@example.com" }

      it "redirects with the same generic success message" do
        perform_request

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq(I18n.t("auth.password_resets.create.success"))
      end

      it "does not deliver an email" do
        expect { perform_request }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end

  describe "PATCH /password-reset/:token" do
    subject(:perform_request) { patch password_reset_token_path(token), params: password_reset_params }

    let(:password_reset_params) do
      {
        password_reset: {
          password: "NewPassword123!",
          password_confirmation:
        }
      }
    end
    let(:password_confirmation) { "NewPassword123!" }
    let(:stored_token) { "reset-token" }
    let(:token) { stored_token }
    let!(:user_identity) do
      create(
        :user_identity,
        password_reset_token_digest: UserIdentity.digest_token(stored_token),
        password_reset_sent_at: 10.minutes.ago
      )
    end

    before do
      create(:session, user: user_identity.user, user_identity:)
    end

    it "updates the password and redirects to sign in" do
      perform_request

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq(I18n.t("auth.password_resets.update.success"))
    end

    it "revokes the user's active sessions" do
      expect { perform_request }.to change { Session.active.where(user: user_identity.user).count }.from(1).to(0)
    end

    context "when the reset link is invalid" do
      let(:token) { "invalid-token" }

      it "renders the form with a safe error message" do
        perform_request

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("auth.password_resets.update.failure"))
      end
    end

    context "when the password confirmation is invalid" do
      let(:password_confirmation) { "Mismatch123!" }

      it "renders the form with a safe error message" do
        perform_request

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("auth.password_resets.update.failure"))
      end
    end
  end
end
