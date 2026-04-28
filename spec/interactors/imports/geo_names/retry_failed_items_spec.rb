require "rails_helper"

RSpec.describe Imports::GeoNames::RetryFailedItems, type: :interactor do
  include ActiveJob::TestHelper

  subject(:result) { described_class.call(input:) }

  let(:input) { { import_run_id: run.id } }
  let(:source) { create(:imports_source, key: "geonames_regions") }
  let!(:run) { create(:imports_run, import_source: source, status: Imports::Run::STATUSES[:partially_failed], finished_at: 1.hour.ago) }
  let!(:failed_item) do
    create(
      :imports_run_item,
      import_run: run,
      item_key: "AD",
      status: Imports::RunItem::STATUSES[:failed],
      attempts_count: 1,
      error_class: "Imports::GeoNames::RegionDumpDownloader::Error",
      error_message: "download failed",
      finished_at: 1.hour.ago
    )
  end
  let!(:succeeded_item) do
    create(:imports_run_item, import_run: run, item_key: "FR", status: Imports::RunItem::STATUSES[:succeeded])
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

  it "requeues failed items only and moves the parent run back to running" do
    expect(result).to be_success

    expect_parent_run_to_be_running
    expect_failed_item_to_be_requeued
    expect(succeeded_item.reload.status).to eq(Imports::RunItem::STATUSES[:succeeded])
    expect(Imports::GeoNames::ImportRunItemJob).to have_been_enqueued.with(failed_item.id).on_queue("imports").once
  end

  context "when import_run_id is missing" do
    let(:input) { {} }

    it "returns a validation failure without enqueueing jobs" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(import_run_id: [ "is missing" ])
      expect(enqueued_jobs).to be_empty
    end
  end

  context "when the run does not exist" do
    let(:input) { { import_run_id: 0 } }

    it "returns a run_not_found failure without enqueueing jobs" do
      expect(result).to be_failure
      expect(result.failure).to eq(
        code: :run_not_found,
        errors: { import_run_id: [ "not found" ] }
      )
      expect(enqueued_jobs).to be_empty
    end
  end

  def expect_parent_run_to_be_running
    expect(run.reload).to have_attributes(
      status: Imports::Run::STATUSES[:running],
      finished_at: nil
    )
  end

  def expect_failed_item_to_be_requeued
    expect(failed_item.reload).to have_attributes(
      status: Imports::RunItem::STATUSES[:queued],
      error_class: nil,
      error_message: nil,
      finished_at: nil,
      attempts_count: 1
    )
  end
end
