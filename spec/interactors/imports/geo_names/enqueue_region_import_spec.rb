require "rails_helper"

RSpec.describe Imports::GeoNames::EnqueueRegionImport, type: :interactor do
  include ActiveJob::TestHelper
  include EnvHelpers

  subject(:result) { described_class.call(settings_interactor:) }

  let(:settings) do
    {
      source_key: "geonames_regions",
      countries: %w[AD FR],
      languages: %w[en ru],
      feature_codes: %w[PCLI ADM1],
      download_alternate_names: true,
      mode: Imports::Run::MODES[:full],
      download_dir: "tmp/imports/geonames",
      initiated_by: "admin/service-actions/geonames-region-import#create"
    }
  end
  let(:settings_interactor) { class_double(Imports::GeoNames::Settings, call: settings_result) }
  let(:settings_result) { result_interactor.call(input: settings) }
  let!(:source) do
    create(
      :imports_source,
      key: "geonames_regions",
      fetch_mode: Imports::Source::FETCH_MODES[:dump],
      license_key: "geonames",
      config: {}
    )
  end

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
  ensure
    clear_enqueued_jobs
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  it "creates one run for the configured source with a persisted settings snapshot and one queued item per country" do
    expect { result }.to change(Imports::Run, :count).by(1)
      .and change(Imports::RunItem, :count).by(2)

    run = result.value!.fetch(:run)

    expect(run.import_source).to eq(source)
    expect_run_snapshot_to_match(run)
    expect_country_items_to_match(run)
  end

  it "does not create or rewrite the GeoNames source metadata" do
    source.update!(
      attribution_text: "Seeded GeoNames",
      compliance_notes: "managed by seeds"
    )

    result

    expect(Imports::Source.where(key: "geonames_regions").count).to eq(1)
    expect(source).to have_attributes(
      attribution_text: "Seeded GeoNames",
      compliance_notes: "managed by seeds"
    )
  end

  it "enqueues one Active Job per item with only the item id" do
    result

    run = result.value!.fetch(:run)

    run.items.each do |item|
      expect(Imports::GeoNames::ImportRunItemJob).to have_been_enqueued.with(item.id).on_queue("imports")
    end
  end

  context "with environment-backed settings" do
    let(:settings_interactor) { Imports::GeoNames::Settings }

    around do |example|
      with_env(
        "GEONAMES_SOURCE_KEY" => "geonames_regions",
        "GEONAMES_COUNTRY_CODES" => "ad, fr",
        "GEONAMES_LANGUAGES" => "en, RU",
        "GEONAMES_FEATURE_CODES" => "PCLI, adm1",
        "GEONAMES_DOWNLOAD_ALTERNATE_NAMES" => "0",
        "GEONAMES_DEFAULT_MODE" => "replay",
        "GEONAMES_DOWNLOAD_DIR" => "tmp/imports/geonames/settings"
      ) do
        load Rails.root.join("config/initializers/01_settings.rb")
        example.run
      end
    ensure
      load Rails.root.join("config/initializers/01_settings.rb")
    end

    it "loads effective settings through the settings interactor" do
      expect { result }.to change(Imports::Run, :count).by(1)
        .and change(Imports::RunItem, :count).by(2)

      run = result.value!.fetch(:run)

      expect_env_settings_snapshot_to_match(run)
    end
  end

  context "when the configured source is missing" do
    before { source.destroy! }

    it "returns a source_not_found failure without creating a run or enqueueing jobs" do
      expect { result }.not_to change(Imports::Run, :count)

      expect(result).to be_failure
      expect(result.failure).to eq(
        code: :source_not_found,
        errors: { source_key: [ "not found" ] }
      )
      expect(enqueued_jobs).to be_empty
    end
  end

  context "when effective settings are invalid" do
    before do
      allow(settings_interactor).to receive(:call).and_return(settings_result)
    end

    let(:settings_result) { result_interactor.call(input: settings.except(:countries)) }

    it "returns a validation failure before creating a run or enqueueing jobs" do
      expect { result }.not_to change(Imports::Run, :count)

      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(countries: [ "is missing" ])
      expect(enqueued_jobs).to be_empty
    end
  end

  context "when normalized item keys collide" do
    let(:settings) { super().merge(countries: %w[AD ad]) }

    it "returns an item conflict failure without keeping a partial run or enqueueing jobs" do
      expect { result }.not_to change(Imports::Run, :count)

      expect(result).to be_failure
      expect(result.failure).to eq(
        code: :run_item_already_exists,
        errors: { item_key: [ "already exists for this run" ] }
      )
      expect(enqueued_jobs).to be_empty
    end
  end

  def expect_run_snapshot_to_match(run)
    expect(run).to have_attributes(
      status: Imports::Run::STATUSES[:running],
      mode: Imports::Run::MODES[:full],
      initiated_by: "admin/service-actions/geonames-region-import#create"
    )
    expect(run.params).to include(
      "countries" => %w[AD FR],
      "languages" => %w[en ru],
      "feature_codes" => %w[PCLI ADM1],
      "download_alternate_names" => true,
      "download_dir" => "tmp/imports/geonames"
    )
    expect(run.params).not_to have_key("queue")
  end

  def expect_env_settings_snapshot_to_match(run)
    expect(run).to have_attributes(
      mode: Imports::Run::MODES[:replay],
      initiated_by: Imports::GeoNames::Settings::DEFAULT_INITIATED_BY
    )
    expect(run.params).to include(
      "countries" => %w[AD FR],
      "feature_codes" => %w[PCLI ADM1],
      "download_alternate_names" => false,
      "download_dir" => "tmp/imports/geonames/settings"
    )
  end

  def expect_country_items_to_match(run)
    expect(run.items.order(:item_key).pluck(:item_kind, :item_key, :status)).to eq(
      [
        [ "country", "AD", Imports::RunItem::STATUSES[:queued] ],
        [ "country", "FR", Imports::RunItem::STATUSES[:queued] ]
      ]
    )
    expect(run.items.find_by!(item_key: "AD").params).to include(
      "countries" => [ "AD" ],
      "country_code" => "AD",
      "artifact_dir" => "tmp/imports/geonames/#{run.id}/AD"
    )
    expect(run.items.find_by!(item_key: "AD").params).not_to have_key("queue")
  end

  def result_interactor
    @result_interactor ||= Class.new(ApplicationInteractor) do
      option :input

      def call
        Success(input)
      end
    end
  end
end
