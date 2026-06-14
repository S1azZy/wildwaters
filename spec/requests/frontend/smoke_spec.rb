# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Frontend smoke page", type: :request do
  describe "GET /frontend/smoke" do
    subject(:perform_request) { get "/frontend/smoke" }

    let(:expected_copy) do
      {
        action: I18n.t("frontend.smoke.action"),
        description: I18n.t("frontend.smoke.description"),
        eyebrow: I18n.t("frontend.smoke.eyebrow"),
        interaction: I18n.t("frontend.smoke.interaction"),
        title: I18n.t("frontend.smoke.title")
      }
    end

    it "renders the Inertia smoke component" do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(inertia).to be_inertia_response
      expect(inertia).to render_component("Frontend/Smoke")
    end

    it "sends translated copy, URLs, and CSRF metadata" do
      perform_request

      expect(inertia).to have_props(
        copy: expected_copy,
        urls: {
          home: root_path
        },
      )
      expect(inertia.props.fetch(:csrfToken)).to be_present
    end

    it "excludes sensitive values from page props" do
      perform_request

      expect(inertia).to have_no_prop(:password)
      expect(inertia).to have_no_prop(:passwordDigest)
      expect(inertia).to have_no_prop(:resetToken)
    end

    it "uses the isolated Inertia layout and JavaScript fallback" do
      perform_request

      expect(response.body).to include(I18n.t("frontend.javascript_required"))
      expect(response.body).to include('href="/vite-test/assets/application-', 'type="module"')
      expect(response.body).to include('meta name="csp-nonce"')
      expect(Rails.root.join("app/views/layouts/inertia.html.erb").read).to include("csrf_meta_tags")
      expect(response.body).not_to include("javascript_importmap_tags", "data-turbo-track")
    end

    it "keeps Vite development origins out of the test content security policy" do
      perform_request

      policy = response.headers.fetch("Content-Security-Policy")

      expect(policy).not_to include("localhost:3036", "127.0.0.1:3036")
    end
  end
end
