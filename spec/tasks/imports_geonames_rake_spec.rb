require "rails_helper"
require "rake"

RSpec.describe "imports:geonames rake tasks" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("imports:geonames:regions")
  end

  before do
    Rake::Task["imports:geonames:regions"].reenable
    if Rake::Task.task_defined?("imports:geonames:regions_from_network")
      Rake::Task["imports:geonames:regions_from_network"].reenable
    end
  end

  after do
    ENV.delete("SOURCE_KEY")
    ENV.delete("COUNTRY_CODES")
    ENV.delete("LANGUAGES")
    ENV.delete("FEATURE_CODES")
    ENV.delete("MODE")
    ENV.delete("INITIATED_BY")
    ENV.delete("ALL_COUNTRIES_PATH")
    ENV.delete("ALTERNATE_NAMES_PATH")
    ENV.delete("DOWNLOAD_DIR")
    ENV.delete("DOWNLOAD_ALTERNATE_NAMES")
  end

  it "downloads GeoNames dumps, configures the source, and runs the import" do
    ENV["COUNTRY_CODES"] = "AD,FR"
    ENV["LANGUAGES"] = "en,ru"
    ENV["SOURCE_KEY"] = "geonames_regions"
    ENV["DOWNLOAD_DIR"] = "tmp/imports/geonames/test"
    ENV["INITIATED_BY"] = "operator"

    allow(Imports::GeoNames::RegionDumpDownloader).to receive(:call).and_return(
      {
        all_countries_path: "/tmp/geonames/all_countries.txt",
        alternate_names_path: "/tmp/geonames/alternate_names.txt"
      }
    )
    allow(Imports::RunSourceJob).to receive(:perform_now)

    expect do
      Rake::Task["imports:geonames:regions_from_network"].invoke
    end.to change(Imports::Source, :count).by(1)

    source = Imports::Source.find_by!(key: "geonames_regions")

    expect(Imports::GeoNames::RegionDumpDownloader).to have_received(:call).with(
      country_codes: %w[AD FR],
      destination_dir: "tmp/imports/geonames/test",
      include_alternate_names: true
    )
    expect(source.config).to include(
      "all_countries_path" => "/tmp/geonames/all_countries.txt",
      "alternate_names_path" => "/tmp/geonames/alternate_names.txt",
      "country_codes" => %w[AD FR],
      "languages" => %w[en ru]
    )
    expect(Imports::RunSourceJob).to have_received(:perform_now).with(
      source_key: "geonames_regions",
      mode: Imports::Run::MODES[:full],
      initiated_by: "operator",
      records: nil
    )
  end
end
