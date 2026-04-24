require "rails_helper"
require "rake"

RSpec.describe Rake::Task do
  subject(:task) { described_class["imports:geonames:enqueue"] }

  let(:settings) { instance_double(Imports::GeoNames::Settings, to_h: settings_input) }
  let(:settings_input) do
    {
      source_key: "geonames_regions",
      countries: %w[AD FR],
      languages: %w[en ru],
      feature_codes: %w[PCLI ADM1],
      download_alternate_names: true,
      mode: Imports::Run::MODES[:full],
      queue: "imports",
      download_dir: "tmp/imports/geonames/test",
      initiated_by: "imports:geonames:enqueue"
    }
  end
  let(:enqueue_result) { result_class.new(run: create(:imports_run)) }
  let(:result_class) do
    Struct.new(:run, keyword_init: true) do
      def success?
        true
      end

      def failure?
        false
      end

      def value!
        { run: }
      end
    end
  end

  before do
    Rails.application.load_tasks unless described_class.task_defined?("imports:geonames:enqueue")
    task.reenable
    described_class["imports:geonames:retry_failed"].reenable
    configure_import_env
    load Rails.root.join("config/initializers/01_settings.rb")
    allow(Imports::GeoNames::Settings).to receive(:from_env).and_return(settings)
    allow(Imports::GeoNames::EnqueueRegionImport).to receive(:call).and_return(enqueue_result)
    allow(Imports::GeoNames::RetryFailedItems).to receive(:call).and_return(enqueue_result)
  end

  after do
    %w[
      GEONAMES_SOURCE_KEY
      GEONAMES_LANGUAGES
      GEONAMES_FEATURE_CODES
      GEONAMES_ALL_COUNTRIES_PATH
      GEONAMES_ALTERNATE_NAMES_PATH
      GEONAMES_DOWNLOAD_DIR
      GEONAMES_DOWNLOAD_ALTERNATE_NAMES
      GEONAMES_DEFAULT_MODE
      GEONAMES_QUEUE
      RUN_ID
    ].each { |key| ENV.delete(key) }
    load Rails.root.join("config/initializers/01_settings.rb")
  end

  it "enqueues a GeoNames region import through the shared interactor" do
    task.invoke

    expect(Imports::GeoNames::Settings).to have_received(:from_env).with(initiated_by: task.name)
    expect(Imports::GeoNames::EnqueueRegionImport).to have_received(:call).with(input: settings_input)
  end

  it "retries failed items for a run through the shared retry interactor" do
    ENV["RUN_ID"] = "123"

    described_class["imports:geonames:retry_failed"].invoke

    expect(Imports::GeoNames::RetryFailedItems).to have_received(:call).with(input: { import_run_id: 123 })
  end

  def configure_import_env
    ENV["GEONAMES_COUNTRIES"] = "AD,FR"
    ENV["GEONAMES_LANGUAGES"] = "en,ru"
    ENV["GEONAMES_SOURCE_KEY"] = "geonames_regions"
    ENV["GEONAMES_DOWNLOAD_DIR"] = "tmp/imports/geonames/test"
    ENV["GEONAMES_QUEUE"] = "imports"
  end
end
