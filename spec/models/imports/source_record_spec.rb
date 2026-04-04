require "rails_helper"

RSpec.describe Imports::SourceRecord, type: :model do
  subject(:source_record) { build(:imports_source_record) }

  describe "associations" do
    it { is_expected.to belong_to(:import_source).class_name("Imports::Source") }
    it { is_expected.to belong_to(:last_import_run).class_name("Imports::Run").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:record_kind) }
    it { is_expected.to validate_presence_of(:external_uid) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:checksum) }
    it { is_expected.to validate_uniqueness_of(:external_uid).scoped_to(:import_source_id, :record_kind) }
  end

  it "defaults normalized_payload to an empty hash" do
    source_record = described_class.new(
      import_source: create(:imports_source),
      record_kind: "region",
      external_uid: "1642911",
      status: "pending",
      checksum: "abc123",
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )

    expect(source_record.normalized_payload).to eq({})
  end
end
