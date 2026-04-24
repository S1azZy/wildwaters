require "rails_helper"
require "rake"

RSpec.describe Rake::Task do
  subject(:task) { described_class["imports:geonames:regions_from_network"] }

  let(:downloaded_paths) do
    {
      all_countries_path: "/tmp/geonames/all_countries.txt",
      alternate_names_path: "/tmp/geonames/alternate_names.txt"
    }
  end

  before do
    Rails.application.load_tasks unless described_class.task_defined?("imports:geonames:regions")
    described_class["imports:geonames:regions"].reenable
    task.reenable if described_class.task_defined?("imports:geonames:regions_from_network")
    configure_import_env
    load Rails.root.join("config/initializers/01_settings.rb")
    allow(Imports::GeoNames::RegionDumpDownloader).to receive(:call).and_return(downloaded_paths)
    allow(Imports::RunSourceJob).to receive(:perform_now)
  end

  after do
    %w[
      GEONAMES_SOURCE_KEY
      GEONAMES_COUNTRY_CODES
      GEONAMES_LANGUAGES
      GEONAMES_FEATURE_CODES
      GEONAMES_ALL_COUNTRIES_PATH
      GEONAMES_ALTERNATE_NAMES_PATH
      GEONAMES_DOWNLOAD_DIR
      GEONAMES_DOWNLOAD_ALTERNATE_NAMES
    ].each { |key| ENV.delete(key) }
    load Rails.root.join("config/initializers/01_settings.rb")
  end

  it "downloads GeoNames dumps, configures the source, and runs the import" do
    expect { task.invoke }.to change(Imports::Source, :count).by(1)

    expect_downloader_to_have_run
    expect_source_config_to_match_downloads
    expect_job_to_have_run
  end

  def configure_import_env
    ENV["GEONAMES_COUNTRY_CODES"] = "AD,FR"
    ENV["GEONAMES_LANGUAGES"] = "en,ru"
    ENV["GEONAMES_SOURCE_KEY"] = "geonames_regions"
    ENV["GEONAMES_DOWNLOAD_DIR"] = "tmp/imports/geonames/test"
  end

  def expect_downloader_to_have_run
    expect(Imports::GeoNames::RegionDumpDownloader).to have_received(:call).with(
      country_codes: %w[AD FR],
      destination_dir: "tmp/imports/geonames/test",
      include_alternate_names: true
    )
  end

  def expect_source_config_to_match_downloads
    expect(import_source.config).to include(
      "all_countries_path" => downloaded_paths.fetch(:all_countries_path),
      "alternate_names_path" => downloaded_paths.fetch(:alternate_names_path),
      "country_codes" => %w[AD FR],
      "languages" => %w[en ru]
    )
  end

  def expect_job_to_have_run
    expect(Imports::RunSourceJob).to have_received(:perform_now).with(
      source_key: "geonames_regions",
      mode: Imports::Run::MODES[:full],
      initiated_by: task.name,
      records: nil
    )
  end

  def import_source
    Imports::Source.find_by!(key: "geonames_regions")
  end
end
