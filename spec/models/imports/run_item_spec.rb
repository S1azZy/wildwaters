require "rails_helper"

RSpec.describe Imports::RunItem, type: :model do
  subject(:run_item) { build(:imports_run_item) }

  it { is_expected.to belong_to(:import_run).class_name("Imports::Run").inverse_of(:items) }

  it "keeps source-specific shard attributes in params instead of dedicated columns" do
    expect(described_class.column_names).not_to include("country_code")
  end

  it "supports generic queued import work items" do
    expect(run_item).to have_attributes(
      item_kind: "country",
      item_key: "AD",
      status: Imports::RunItem::STATUSES[:queued],
      params: {},
      artifact_paths: {},
      stats: {},
      attempts_count: 0
    )
  end

  it "prevents duplicate work items within the same run" do
    existing_item = create(:imports_run_item, item_kind: "country", item_key: "AD")
    duplicate = build(:imports_run_item, import_run: existing_item.import_run, item_kind: "country", item_key: "AD")

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the parent run to represent partial country failures" do
    run = create(:imports_run, status: Imports::Run::STATUSES[:partially_failed])

    expect(run).to be_status_partially_failed
  end
end
