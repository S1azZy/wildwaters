require "rails_helper"

RSpec.describe Imports::SourceRecords::ReconcileMissingUpstream, type: :interactor do
  subject(:result) { described_class.call(input:) }

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
  let!(:run) { create(:imports_run, import_source: source, mode: Imports::Run::MODES[:full]) }
  let(:records) do
    [
      {
        record_kind: "region",
        external_uid: "3041565"
      }
    ]
  end
  let(:input) do
    {
      import_run_id: run.id,
      records:,
      country_code: "AD"
    }
  end

  it "marks only missing records inside the requested country shard" do
    old_ad_record = create_source_record(external_uid: "old-ad", country_code: "AD")
    old_fr_record = create_source_record(external_uid: "old-fr", country_code: "FR")
    seen_ad_record = create_source_record(external_uid: "3041565", country_code: "AD")

    expect(result).to be_success
    expect(result.value!.fetch(:stats)).to eq("missing_upstream_count" => 1)
    expect(old_ad_record.reload).to have_attributes(
      status: Imports::SourceRecord::STATUSES[:missing_upstream],
      last_import_run: run
    )
    expect(old_fr_record.reload.status).to eq(Imports::SourceRecord::STATUSES[:matched])
    expect(seen_ad_record.reload.status).to eq(Imports::SourceRecord::STATUSES[:matched])
  end

  it "does nothing for incremental runs" do
    run.update!(mode: Imports::Run::MODES[:incremental])
    old_ad_record = create_source_record(external_uid: "old-ad", country_code: "AD")

    expect(result).to be_success
    expect(result.value!.fetch(:stats)).to eq("missing_upstream_count" => 0)
    expect(old_ad_record.reload.status).to eq(Imports::SourceRecord::STATUSES[:matched])
  end

  context "when country_code is missing" do
    let(:input) { super().except(:country_code) }

    it "returns validation failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(country_code: [ "is missing" ])
    end
  end

  def create_source_record(external_uid:, country_code:)
    create(
      :imports_source_record,
      import_source: source,
      last_import_run: nil,
      external_uid:,
      status: Imports::SourceRecord::STATUSES[:matched],
      normalized_payload: { "country_code" => country_code }
    )
  end
end
