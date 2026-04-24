require "rails_helper"

RSpec.describe Imports::GeoNames::ImportRunItemJob, type: :job do
  let!(:source) do
    create(
      :imports_source,
      key: "geonames_regions",
      target_kind: "region",
      source_role: Imports::Source::SOURCE_ROLES[:canonical_identity],
      fetch_mode: Imports::Source::FETCH_MODES[:dump],
      license_key: "geonames",
      display_policy: Imports::Source::DISPLAY_POLICIES[:public_display_allowed]
    )
  end
  let!(:run) do
    create(
      :imports_run,
      import_source: source,
      mode: Imports::Run::MODES[:full],
      status: Imports::Run::STATUSES[:running],
      params: {
        "source_key" => source.key,
        "countries" => [ "AD" ],
        "languages" => %w[en ru ca fr es],
        "feature_codes" => %w[PCLI ADM1 PPLA PPLC],
        "download_alternate_names" => true,
        "download_dir" => "tmp/imports/geonames"
      }
    )
  end
  let!(:item) do
    create(
      :imports_run_item,
      import_run: run,
      item_key: "AD",
      country_code: "AD",
      params: run.params.merge("country_code" => "AD")
    )
  end
  let(:downloaded_paths) do
    {
      all_countries_path: "spec/fixtures/imports/geonames/country_AD.txt",
      alternate_names_path: "spec/fixtures/imports/geonames/alternate_names_AD.txt"
    }
  end

  before do
    allow(Imports::GeoNames::RegionDumpDownloader).to receive(:call).and_return(downloaded_paths)
  end

  it "imports one country item into the existing run and records item artifacts and stats" do
    run_count = Imports::Run.count

    expect do
      described_class.perform_now(item.id)
    end.to change(Region, :count).by(15)

    expect(Imports::Run.count).to eq(run_count)
    expect_downloader_to_have_run_for_item
    expect_item_to_be_succeeded
    expect(run.reload.status).to eq(Imports::Run::STATUSES[:succeeded])
  end

  def expect_downloader_to_have_run_for_item
    expect(Imports::GeoNames::RegionDumpDownloader).to have_received(:call).with(
      country_codes: [ "AD" ],
      destination_dir: Rails.root.join("tmp/imports/geonames", run.id.to_s, "AD").to_s,
      include_alternate_names: true
    )
  end

  def expect_item_to_be_succeeded
    expect(item.reload).to have_attributes(
      status: Imports::RunItem::STATUSES[:succeeded],
      artifact_paths: downloaded_paths.stringify_keys,
      error_class: nil,
      error_message: nil
    )
    expect(item.stats).to include(
      "record_count" => 15,
      "processed_count" => 15,
      "missing_upstream_count" => 0
    )
  end
end
