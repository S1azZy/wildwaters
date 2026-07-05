# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin service actions", type: :request do
  include ActiveJob::TestHelper

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
  ensure
    clear_enqueued_jobs
    ActiveJob::Base.queue_adapter = previous_adapter
  end

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
        importRegions: {
          title: I18n.t("admin.service_actions.import_regions.title", locale:),
          description: I18n.t("admin.service_actions.import_regions.description", locale:),
          button: I18n.t("admin.service_actions.import_regions.button", locale:),
          emptyTitle: I18n.t("admin.service_actions.import_regions.empty_title", locale:),
          emptyDescription: I18n.t("admin.service_actions.import_regions.empty_description", locale:),
          latestRunTitle: I18n.t("admin.service_actions.import_regions.latest_run_title", locale:),
          settingsTitle: I18n.t("admin.service_actions.import_regions.settings_title", locale:),
          resultsTitle: I18n.t("admin.service_actions.import_regions.results_title", locale:),
          failureTitle: I18n.t("admin.service_actions.import_regions.failure_title", locale:),
          fields: {
            status: I18n.t("admin.service_actions.import_regions.fields.status", locale:),
            mode: I18n.t("admin.service_actions.import_regions.fields.mode", locale:),
            initiatedBy: I18n.t("admin.service_actions.import_regions.fields.initiated_by", locale:),
            startedAt: I18n.t("admin.service_actions.import_regions.fields.started_at", locale:),
            finishedAt: I18n.t("admin.service_actions.import_regions.fields.finished_at", locale:),
            countries: I18n.t("admin.service_actions.import_regions.fields.countries", locale:),
            languages: I18n.t("admin.service_actions.import_regions.fields.languages", locale:),
            featureCodes: I18n.t("admin.service_actions.import_regions.fields.feature_codes", locale:),
            itemCounts: I18n.t("admin.service_actions.import_regions.fields.item_counts", locale:)
          },
          statusLabels: Imports::Run::STATUSES.to_h do |_key, status|
            [ status.camelize(:lower).to_sym, I18n.t("admin.service_actions.import_regions.statuses.#{status}", locale:) ]
          end
        }
      },
      navigation: {
        sections: admin_navigation_sections(current: "service_actions", locale:)
      },
      urls: {
        serviceActions: admin_service_actions_path,
        geonamesRegionImport: admin_service_actions_geonames_region_import_path
      },
      geonamesImport: {
        latestRun: nil
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
          expect(inertia.props.keys).to contain_exactly("copy", "errors", "geonamesImport", "navigation", "shell", "urls")
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

        it "does not enqueue imports or jobs while rendering the page" do
          expect { perform_request }.not_to change(Imports::Run, :count)
          expect(enqueued_jobs).to be_empty
        end

        it "uses the isolated Inertia runtime document" do
          perform_request

          expect_inertia_runtime_document!
        end
      end
    end
  end

  it_behaves_like "admin service actions access", :admin_service_actions_path

  describe "GET /admin/service-actions GeoNames import summary" do
    let(:admin_user) { create(:user, role: "admin") }
    let(:admin_identity) { create(:user_identity, user: admin_user, email: "admin@example.com") }
    let!(:source) { geonames_source }

    before do
      sign_in_as(admin_identity)
    end

    it "renders an empty latest-run state when GeoNames import has never run" do
      get admin_service_actions_path

      expect(inertia).to have_props(
        "geonamesImport" => {
          "latestRun" => nil
        }
      )
    end

    it "renders the latest GeoNames import run summary without sensitive state" do
      latest_run = create_latest_geonames_run

      get admin_service_actions_path

      expect_latest_geonames_run_props(latest_run)
      expect(nested_keys(inertia.props)).not_to include(*admin_sensitive_prop_keys)
    end
  end

  describe "POST /admin/service-actions/geonames-region-import" do
    let!(:source) { geonames_source }

    it "redirects guests to sign in without enqueueing import work" do
      expect do
        post admin_service_actions_geonames_region_import_path
      end.not_to change(Imports::Run, :count)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication"))
      expect(enqueued_jobs).to be_empty
    end

    it "redirects members to the explore homepage without enqueueing import work" do
      sign_in_as(create(:user_identity))

      expect do
        post admin_service_actions_geonames_region_import_path
      end.not_to change(Imports::Run, :count)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("admin.authorization.required"))
      expect(enqueued_jobs).to be_empty
    end

    it "enqueues a GeoNames import from environment-backed settings for admins" do
      sign_in_as(create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com"))

      with_geonames_env do
        expect_admin_import_enqueue
      end

      expect(response).to redirect_to(admin_service_actions_path)
      expect(flash[:notice]).to eq(I18n.t("admin.service_actions.import_regions.flash.enqueued"))
      expect_created_admin_import_run
    end

    it "reports active-run failure without enqueueing duplicate work" do
      create(:imports_run, import_source: source, status: Imports::Run::STATUSES[:running])
      sign_in_as(create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com"))

      with_geonames_env do
        expect do
          post admin_service_actions_geonames_region_import_path
        end.not_to change(Imports::Run, :count)
      end

      expect(response).to redirect_to(admin_service_actions_path)
      expect(flash[:alert]).to eq(I18n.t("admin.service_actions.import_regions.flash.run_already_active"))
      expect(enqueued_jobs).to be_empty
    end
  end

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
      token
      user
    ]
  end

  def geonames_source
    create(
      :imports_source,
      key: "geonames_regions",
      fetch_mode: Imports::Source::FETCH_MODES[:dump],
      license_key: "geonames",
      config: {}
    )
  end

  def create_latest_geonames_run
    create(:imports_run, import_source: source, started_at: 2.days.ago, initiated_by: "older")
    latest_run = create(:imports_run, latest_geonames_run_attributes)
    create(:imports_run_item, import_run: latest_run, item_key: "AD", status: Imports::RunItem::STATUSES[:succeeded])
    create(:imports_run_item, import_run: latest_run, item_key: "FR", status: Imports::RunItem::STATUSES[:failed], error_message: "HTTP 500")
    latest_run
  end

  def latest_geonames_run_attributes
    {
      import_source: source,
      mode: Imports::Run::MODES[:full],
      status: Imports::Run::STATUSES[:partially_failed],
      started_at: Time.zone.parse("2026-07-05 10:00:00 UTC"),
      finished_at: Time.zone.parse("2026-07-05 10:03:00 UTC"),
      initiated_by: "admin/service-actions/geonames-region-import#create",
      params: latest_geonames_run_params,
      stats: latest_geonames_run_stats,
      error_class: "Imports::GeoNames::DownloadError",
      error_message: "Unable to download GeoNames dump"
    }
  end

  def latest_geonames_run_params
    {
      "countries" => %w[AD FR],
      "languages" => %w[en ru],
      "feature_codes" => %w[PCLI ADM1],
      "download_alternate_names" => true,
      "download_dir" => "tmp/imports/geonames"
    }
  end

  def latest_geonames_run_stats
    {
      "processed_count" => 12,
      "created_region_count" => 3,
      "missing_upstream_count" => 1
    }
  end

  def expect_latest_geonames_run_props(latest_run)
    expect(inertia.props.dig("geonamesImport", "latestRun")).to include(
      expected_latest_geonames_run_props(latest_run)
    )
  end

  def expected_latest_geonames_run_props(latest_run)
    {
      "id" => latest_run.id,
      "status" => Imports::Run::STATUSES[:partially_failed],
      "mode" => Imports::Run::MODES[:full],
      "initiatedBy" => "admin/service-actions/geonames-region-import#create",
      "startedAt" => latest_run.started_at.iso8601,
      "finishedAt" => latest_run.finished_at.iso8601,
      "settings" => expected_latest_settings,
      "stats" => expected_latest_stats,
      "itemCounts" => { "succeeded" => 1, "failed" => 1 },
      "failure" => expected_latest_failure
    }
  end

  def expected_latest_settings
    {
      "countries" => %w[AD FR],
      "languages" => %w[en ru],
      "featureCodes" => %w[PCLI ADM1],
      "downloadAlternateNames" => true,
      "downloadDir" => "tmp/imports/geonames"
    }
  end

  def expected_latest_stats
    {
      "processedCount" => 12,
      "createdRegionCount" => 3,
      "missingUpstreamCount" => 1
    }
  end

  def expected_latest_failure
    {
      "className" => "Imports::GeoNames::DownloadError",
      "message" => "Unable to download GeoNames dump",
      "itemMessages" => [ "FR: HTTP 500" ]
    }
  end

  def expect_admin_import_enqueue
    expect do
      post admin_service_actions_geonames_region_import_path
    end.to change(Imports::Run, :count).by(1)
      .and change(Imports::RunItem, :count).by(2)
  end

  def expect_created_admin_import_run
    run = Imports::Run.order(:created_at).last

    expect(run).to have_attributes(import_source: source, initiated_by: "admin/service-actions/geonames-region-import#create", status: Imports::Run::STATUSES[:running])
    expect(run.params).to include(
      "countries" => %w[AD FR],
      "languages" => %w[en ru],
      "feature_codes" => %w[PCLI ADM1],
      "download_alternate_names" => false,
      "download_dir" => "tmp/imports/geonames/admin"
    )
    run.items.each { |item| expect(Imports::GeoNames::ImportRunItemJob).to have_been_enqueued.with(item.id).on_queue("imports") }
  end

  def with_geonames_env(&)
    with_env(
      "GEONAMES_SOURCE_KEY" => "geonames_regions",
      "GEONAMES_COUNTRY_CODES" => "ad, fr",
      "GEONAMES_LANGUAGES" => "en, RU",
      "GEONAMES_FEATURE_CODES" => "PCLI, adm1",
      "GEONAMES_DOWNLOAD_ALTERNATE_NAMES" => "0",
      "GEONAMES_DEFAULT_MODE" => "full",
      "GEONAMES_DOWNLOAD_DIR" => "tmp/imports/geonames/admin"
    ) do
      load Rails.root.join("config/initializers/01_settings.rb")
      yield
    ensure
      load Rails.root.join("config/initializers/01_settings.rb")
    end
  end
end
