require "rails_helper"

RSpec.describe Imports::GeoNames::FinalizeRun, type: :interactor do
  subject(:result) { described_class.call(input: { import_run_id: run.id }) }

  let(:source) { create(:imports_source, key: "geonames_regions") }
  let(:run) { create(:imports_run, import_source: source, status: Imports::Run::STATUSES[:running]) }

  it "keeps the parent run running while any country item is still active" do
    create(:imports_run_item, import_run: run, item_key: "AD", status: Imports::RunItem::STATUSES[:succeeded])
    create(:imports_run_item, import_run: run, item_key: "FR", country_code: "FR", status: Imports::RunItem::STATUSES[:queued])

    expect(result).to be_success
    expect(run.reload.status).to eq(Imports::Run::STATUSES[:running])
  end

  it "marks the parent run partially_failed when all items are terminal and at least one failed" do
    create(:imports_run_item, import_run: run, item_key: "AD", status: Imports::RunItem::STATUSES[:succeeded], stats: { "processed_count" => 10 })
    create(:imports_run_item, import_run: run, item_key: "FR", country_code: "FR", status: Imports::RunItem::STATUSES[:failed], stats: { "processed_count" => 2 })

    expect(result).to be_success
    expect(run.reload).to have_attributes(status: Imports::Run::STATUSES[:partially_failed])
    expect(run.stats).to include(
      "total_item_count" => 2,
      "succeeded_item_count" => 1,
      "failed_item_count" => 1,
      "processed_count" => 12
    )
  end
end
