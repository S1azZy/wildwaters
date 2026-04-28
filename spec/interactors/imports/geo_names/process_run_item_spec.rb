require "rails_helper"

RSpec.describe Imports::GeoNames::ProcessRunItem, type: :interactor do
  subject(:result) do
    described_class.call(
      input:,
      download_region_dump: steps.fetch(:download_region_dump),
      build_region_dataset: steps.fetch(:build_region_dataset),
      apply_dataset: steps.fetch(:apply_dataset),
      reconcile_missing_upstream: steps.fetch(:reconcile_missing_upstream),
      finalize_run:
    )
  end

  let(:input) { { import_run_item_id: item.id } }
  let(:steps) do
    {
      download_region_dump: step_double(success(downloaded_paths)),
      build_region_dataset: step_double(success(records:)),
      apply_dataset: step_double(success(stats:)),
      reconcile_missing_upstream: step_double(success(stats: { "missing_upstream_count" => 0 }))
    }
  end
  let(:finalize_run) { Imports::GeoNames::FinalizeRun }
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
      params: run.params.merge("country_code" => "AD")
    )
  end

  it "imports one country item into the existing run and records item artifacts and stats" do
    run_count = Imports::Run.count

    result

    expect(result).to be_success
    expect(Imports::Run.count).to eq(run_count)
    expect_steps_to_have_run_for_item
    expect_item_to_be_succeeded
    expect(run.reload.status).to eq(Imports::Run::STATUSES[:succeeded])
  end

  context "when import_run_item_id is missing" do
    let(:input) { {} }

    it "returns a validation failure before importing anything" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(import_run_item_id: [ "is missing" ])
    end
  end

  context "when the item does not exist" do
    let(:input) { { import_run_item_id: 0 } }

    it "returns a run_item_not_found failure" do
      expect(result).to be_failure
      expect(result.failure).to eq(
        code: :run_item_not_found,
        errors: { import_run_item_id: [ "not found" ] }
      )
    end
  end

  context "when the item already succeeded" do
    before { item.update!(status: Imports::RunItem::STATUSES[:succeeded]) }

    it "skips the import without changing attempts" do
      expect { result }.not_to change { item.reload.attempts_count }

      expect(result).to be_success
      expect(steps.fetch(:download_region_dump)).not_to have_received(:call)
    end
  end

  context "when the dataset import fails" do
    let(:steps) do
      super().merge(
        apply_dataset: step_double(failure(code: :source_disabled, errors: { import_source: [ "is disabled" ] }))
      )
    end

    it "marks the item failed and finalizes the parent run without raising a job-level failure" do
      expect(result).to be_success
      expect(item.reload).to have_attributes(
        status: Imports::RunItem::STATUSES[:failed],
        error_class: "source_disabled"
      )
      expect(run.reload.status).to eq(Imports::Run::STATUSES[:partially_failed])
    end
  end

  def expect_steps_to_have_run_for_item
    expect(steps.fetch(:download_region_dump)).to have_received(:call).with(
      input: {
        country_code: "AD",
        destination_dir: Rails.root.join("tmp/imports/geonames", run.id.to_s, "AD").to_s,
        include_alternate_names: true
      }
    )
    expect(steps.fetch(:build_region_dataset)).to have_received(:call).with(
      input: {
        country_codes: [ "AD" ],
        languages: %w[en ru ca fr es],
        feature_codes: %w[PCLI ADM1 PPLA PPLC],
        all_countries_path: downloaded_paths.fetch(:all_countries_path),
        alternate_names_path: downloaded_paths[:alternate_names_path]
      }
    )
    expect(steps.fetch(:apply_dataset)).to have_received(:call).with(
      input: {
        import_run_id: run.id,
        records:
      }
    )
    expect(steps.fetch(:reconcile_missing_upstream)).to have_received(:call).with(
      input: {
        import_run_id: run.id,
        records:,
        country_code: "AD"
      }
    )
  end

  def downloaded_paths
    {
      all_countries_path: "spec/fixtures/imports/geonames/country_AD.txt",
      alternate_names_path: "spec/fixtures/imports/geonames/alternate_names_AD.txt"
    }
  end

  def records
    Imports::GeoNames::BuildRegionDataset.call(input: dataset_input).value!.fetch(:records)
  end

  def dataset_input
    {
      country_codes: [ "AD" ],
      languages: %w[en ru ca fr es],
      feature_codes: %w[PCLI ADM1 PPLA PPLC],
      all_countries_path: downloaded_paths.fetch(:all_countries_path),
      alternate_names_path: downloaded_paths[:alternate_names_path]
    }
  end

  def stats
    {
      "record_count" => 15,
      "processed_count" => 15,
      "created_region_count" => 15
    }
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

  def success(value = {})
    result_interactor.call(input: { value:, success: true })
  end

  def failure(error)
    result_interactor.call(input: { value: error, success: false })
  end

  def step_double(result)
    class_double(ApplicationInteractor).tap do |step|
      allow(step).to receive(:call).and_return(result)
    end
  end

  def result_interactor
    @result_interactor ||= Class.new(ApplicationInteractor) do
      option :input

      def call
        return Success(input.fetch(:value)) if input.fetch(:success)

        Failure(input.fetch(:value))
      end
    end
  end
end
