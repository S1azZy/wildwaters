require "rails_helper"

RSpec.describe "Authentication", type: :request do
  def expect_auth_shell_response!(body, title:, prompt:, link:, include_locale: false)
    expect(body).to include("data-ui=\"auth-shell\"")
    expect(body).to include(title)
    expect(body).to include(prompt)
    expect(body).to include(link)
    expect(body).to include(I18n.t("auth.fields.locale")) if include_locale
  end

  def sign_in_with_locale(locale)
    user = create(:user, locale:)
    create(:user_identity, user:, email: "user@example.com")

    post session_path, params: {
      session: {
        email: "user@example.com",
        password: "Password123!"
      }
    }
  end

  describe "GET /session/new" do
    subject(:perform_request) { get new_session_path }

    it "renders the sign-in page with its recovery and registration links" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("auth.sessions.new.forgot_password"))
      expect_auth_shell_response!(
        response.body,
        title: I18n.t("auth.sessions.new.heading"),
        prompt: ERB::Util.html_escape(I18n.t("auth.sessions.new.sign_up_prompt")),
        link: I18n.t("auth.sessions.new.sign_up_link")
      )
    end

    context "when the user is already authenticated" do
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

      it "redirects to the explore homepage" do
        perform_request

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /registration/new" do
    subject(:perform_request) { get new_registration_path }

    it "renders the sign-up page with its locale field and sign-in link" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect_auth_shell_response!(
        response.body,
        title: I18n.t("auth.registrations.new.heading"),
        prompt: I18n.t("auth.registrations.new.sign_in_prompt"),
        link: I18n.t("auth.registrations.new.sign_in_link"),
        include_locale: true
      )
    end
  end

  describe "GET /password-reset/new" do
    subject(:perform_request) { get new_password_reset_path }

    it "renders the password reset request page inside the shared auth shell" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect_auth_shell_response!(
        response.body,
        title: I18n.t("auth.password_resets.new.heading"),
        prompt: I18n.t("auth.password_resets.new.sign_in_prompt"),
        link: I18n.t("auth.password_resets.new.sign_in_link")
      )
    end
  end

  describe "GET /password-reset/:token" do
    subject(:perform_request) { get password_reset_token_path(token) }

    let(:token) { "example-token" }

    it "renders the password reset form inside the shared auth shell" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect_auth_shell_response!(
        response.body,
        title: I18n.t("auth.password_resets.edit.heading"),
        prompt: I18n.t("auth.password_resets.edit.sign_in_prompt"),
        link: I18n.t("auth.password_resets.edit.sign_in_link")
      )
      expect(response.body).to include(I18n.t("auth.password_resets.edit.submit"))
    end
  end

  describe "GET /dashboard" do
    subject(:perform_request) { get dashboard_path }

    it "redirects unauthenticated users to sign in" do
      I18n.with_locale(:ru) { perform_request }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication", locale: :en))
    end

    context "when authenticated with a Russian locale" do
      before { sign_in_with_locale("ru") }

      it "renders translations in Russian" do
        perform_request

        expect(response.body).to include(I18n.t("dashboard.show.heading", locale: :ru))
      end

      it "does not leak its locale into a later guest request" do
        perform_request
        expect(response.body).to include(I18n.t("dashboard.show.heading", locale: :ru))

        delete session_path
        get new_session_path

        expect(response.body).to include(I18n.t("auth.sessions.new.heading", locale: :en))
        expect(response.body).not_to include(I18n.t("auth.sessions.new.heading", locale: :ru))
      end
    end

    context "when authenticated with an English locale" do
      before { sign_in_with_locale("en") }

      it "renders translations in English" do
        perform_request

        expect(response.body).to include(I18n.t("dashboard.show.heading", locale: :en))
      end
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

    it "signs in and redirects to the explore homepage" do
      expect { perform_request }.to change(Session, :count).by(1)

      expect(response).to redirect_to(root_path)
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
