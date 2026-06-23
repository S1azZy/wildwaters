require "rails_helper"

RSpec.describe "Authentication", type: :request do
  def expect_auth_shell_response!(body, title:, prompt:, link:, include_locale: false)
    expect(body).to include("data-ui=\"auth-shell\"")
    expect(body).to include(title)
    expect(body).to include(prompt)
    expect(body).to include(link)
    expect(body).to include(I18n.t("auth.fields.locale")) if include_locale
  end

  def sign_in_with_locale(locale, email: "user@example.com")
    user = create(:user, locale:)
    create(:user_identity, user:, email:)

    post session_path, params: {
      session: {
        email:,
        password: "Password123!"
      }
    }

    user
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

    def expected_shell_labels(locale:)
      {
        brandName: I18n.t("layouts.header.brand_name", locale:),
        brandTagline: I18n.t("layouts.header.brand_tagline", locale:),
        explore: I18n.t("layouts.header.explore", locale:),
        profile: I18n.t("layouts.header.profile", locale:),
        signIn: I18n.t("layouts.header.sign_in", locale:)
      }
    end
    let(:expected_shell_urls) do
      {
        dashboard: dashboard_path,
        explore: root_path,
        signIn: new_session_path
      }
    end
    let(:sensitive_prop_keys) do
      %w[
        credential
        credentials
        current_user
        email
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

    it "redirects unauthenticated users to sign in" do
      I18n.with_locale(:ru) { perform_request }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication", locale: :en))
    end

    context "when authenticated with a Russian locale" do
      let!(:user) { sign_in_with_locale("ru", email: "russian@example.com") }

      it "renders the localized Dashboard Inertia page with the exact protected contract" do
        perform_request

        expect_dashboard_inertia_contract!(locale: :ru, user:)
      end

      it "does not leak its locale into a later guest request" do
        perform_request
        expect(inertia.props.dig("copy", "heading")).to eq(I18n.t("dashboard.show.heading", locale: :ru))

        delete session_path
        get new_session_path

        expect(response.body).to include(I18n.t("auth.sessions.new.heading", locale: :en))
        expect(response.body).not_to include(I18n.t("auth.sessions.new.heading", locale: :ru))
      end
    end

    context "when authenticated with an English locale" do
      let!(:user) { sign_in_with_locale("en", email: "english@example.com") }

      it "renders the English Dashboard Inertia copy and isolated runtime" do
        perform_request

        expect_dashboard_inertia_contract!(locale: :en, user:)
        expect_dashboard_inertia_runtime!
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

  def nested_keys(value)
    case value
    when Hash
      value.flat_map { |key, nested_value| [ key, *nested_keys(nested_value) ] }
    when Array
      value.flat_map { |nested_value| nested_keys(nested_value) }
    else
      []
    end
  end

  def expect_dashboard_inertia_contract!(locale:, user:)
    expect(response).to have_http_status(:ok)
    expect(inertia).to be_inertia_response
    expect(inertia).to render_component("Dashboard/Show")
    expect_dashboard_props!(locale:, user:)
    expect(nested_keys(inertia.props)).not_to include(*sensitive_prop_keys)
  end

  def expect_dashboard_props!(locale:, user:)
    expect(inertia.props.keys).to contain_exactly("copy", "errors", "shell", "urls")
    expect(inertia.props.fetch("errors")).to eq({})
    expect(inertia).to have_props(
      copy: expected_dashboard_copy(locale:, user:),
      shell: {
        authenticated: true,
        labels: expected_shell_labels(locale:),
        urls: expected_shell_urls
      },
      urls: {
        signOut: session_path
      }
    )
  end

  def expected_dashboard_copy(locale:, user:)
    {
      title: I18n.t("dashboard.show.title", locale:),
      heading: I18n.t("dashboard.show.heading", locale:),
      signedInAs: I18n.t("dashboard.show.signed_in_as", locale:, email: user.primary_email),
      signOut: I18n.t("dashboard.show.sign_out", locale:)
    }
  end

  def expect_dashboard_inertia_runtime!
    expect(response.body).to include(I18n.t("frontend.javascript_required"))
    expect(response.body).to include('href="/vite-test/assets/application-', 'type="module"')
    expect(response.body).not_to include("javascript_importmap_tags", "data-turbo-track")
  end
end
