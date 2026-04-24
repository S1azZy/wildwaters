require "rails_helper"

RSpec.describe Imports::RunItem, type: :model do
  subject(:run_item) { build(:imports_run_item) }

  it { is_expected.to belong_to(:import_run).class_name("Imports::Run").inverse_of(:items) }

  it "supports the queued country item state required by GeoNames orchestration" do
    expect(run_item).to have_attributes(
      item_kind: "country",
      item_key: "AD",
      country_code: "AD",
      status: Imports::RunItem::STATUSES[:queued],
      params: {},
      artifact_paths: {},
      stats: {},
      attempts_count: 0
    )
  end

  it "prevents duplicate country items within the same run" do
    existing_item = create(:imports_run_item, item_key: "AD", country_code: "AD")
    duplicate = build(:imports_run_item, import_run: existing_item.import_run, item_key: "AD", country_code: "AD")

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the parent run to represent partial country failures" do
    run = create(:imports_run, status: Imports::Run::STATUSES[:partially_failed])

    expect(run).to be_status_partially_failed
  end
end
