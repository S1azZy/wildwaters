require "rails_helper"

RSpec.describe Imports::Regions::ApplySourceRecord, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:source) { create(:imports_source, key: "geonames_regions") }
  let(:run) { create(:imports_run, import_source: source) }
  let(:record) do
    {
      record_kind: "region",
      external_uid: "1643084",
      external_url: "https://www.geonames.org/1643084",
      name: "Indonesia",
      ascii_name: "Indonesia",
      region_kind: "country",
      country_code: "ID",
      parent_external_uid: nil,
      latitude: -2.5,
      longitude: 118.0,
      alternate_names: []
    }
  end
  let(:input) { { source:, run:, record: } }

  context "when required input is missing" do
    let(:input) { { source:, run: } }

    it "returns a validation failure before touching persistence" do
      expect { result }.not_to change(Imports::SourceRecord, :count)
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(record: [ "is missing" ])
    end
  end

  it "creates region provenance, a changed-payload snapshot, and searchable names" do
    expect { result }.to change(Imports::SourceRecord, :count).by(1)
      .and change(Imports::RecordSnapshot, :count).by(1)
      .and change(Region, :count).by(1)
      .and change(Imports::RegionSourceLink, :count).by(1)

    expect(result).to be_success
    expect_created_import_state
  end

  it "reapplies an unchanged record without duplicating persisted import state" do
    result

    expect do
      described_class.call(input:)
    end.not_to change {
      [
        Imports::SourceRecord.count,
        Imports::RecordSnapshot.count,
        Region.count,
        Imports::RegionSourceLink.count,
        RegionName.count
      ]
    }
  end

  it "captures a new snapshot when the normalized payload changes" do
    result
    previous_changed_at = source_record_for("1643084").last_changed_at

    expect do
      described_class.call(input: input.merge(record: changed_record))
    end.to change(Imports::RecordSnapshot, :count).by(1)

    expect_changed_snapshot(previous_changed_at)
  end

  it "attaches a structural local match without duplicating the region" do
    existing_region = create_structural_match

    expect { result }.not_to change(Region, :count)

    expect(source_record_for("1643084").region_source_link).to have_attributes(
      region: existing_region,
      match_strategy: "structural_match"
    )
  end

  it "fails when a parent source record has not been linked to a region" do
    result = described_class.call(input: input.merge(record: child_record))

    expect(result).to be_failure
    expect(result.failure).to eq(
      code: :parent_not_found,
      errors: { parent_external_uid: [ "not found" ] }
    )
  end

  it "links child records to an imported parent region" do
    result
    child_result = described_class.call(input: input.merge(record: child_record))

    expect(child_result).to be_success
    expect_child_region_linked_to_parent
  end

  it "syncs alternate names from the source record" do
    described_class.call(input: input.merge(record: alternate_record))

    expect(region_for("1643084").region_names.pluck(:name, :language_code, :name_role, :preferred)).to include(
      [ "Indonesien", "de", RegionName::NAME_ROLES[:alias], false ],
      [ "Индонезия", "ru", RegionName::NAME_ROLES[:preferred], true ]
    )
  end

  def expect_created_import_state
    source_record = source_record_for("1643084")
    region = source_record.region_source_link.region

    expect(source_record).to have_attributes(source_record_attributes)
    expect(source_record.record_snapshots.last).to have_attributes(import_run: run, checksum: source_record.checksum)
    expect(region).to have_attributes(name: "Indonesia", region_kind: Region::REGION_KINDS[:country], country_code: "ID")
    expect(region.center.longitude).to eq(118.0)
    expect(region.center.latitude).to eq(-2.5)
    expect(source_record.region_source_link).to have_attributes(match_strategy: "structural_match", primary_identity: true, confidence: 1.0)
    expect(region.region_names.pluck(:name, :language_code, :name_role, :preferred)).to include(
      [ "Indonesia", nil, RegionName::NAME_ROLES[:primary], true ],
      [ "Indonesia", "en", RegionName::NAME_ROLES[:ascii], false ]
    )
  end

  def source_record_attributes
    {
      status: Imports::SourceRecord::STATUSES[:matched],
      external_url: "https://www.geonames.org/1643084",
      last_import_run: run
    }
  end

  def changed_record
    record.merge(name: "Republic of Indonesia", ascii_name: "Republic of Indonesia")
  end

  def expect_changed_snapshot(previous_changed_at)
    source_record = source_record_for("1643084").reload

    expect(source_record.last_changed_at).to be > previous_changed_at
    expect(source_record.normalized_payload).to include("name" => "Republic of Indonesia", "ascii_name" => "Republic of Indonesia")
    expect(source_record.region_source_link.region.reload.name).to eq("Republic of Indonesia")
  end

  def create_structural_match
    create(:region, name: "Indonesia", slug: "indonesia", region_kind: Region::REGION_KINDS[:country], country_code: "ID")
  end

  def child_record
    record.merge(
      external_uid: "1650535",
      name: "Bali",
      ascii_name: "Bali",
      region_kind: Region::REGION_KINDS[:area],
      parent_external_uid: "1643084"
    )
  end

  def expect_child_region_linked_to_parent
    parent_region = region_for("1643084")
    child_region = region_for("1650535")

    expect(child_region.parent).to eq(parent_region)
    expect(child_region.ancestor_closures.pluck(:ancestor_id)).to include(parent_region.id)
  end

  def alternate_record
    record.merge(
      alternate_names: [
        { name: "Indonesien", language_code: "de", name_role: RegionName::NAME_ROLES[:alias] },
        { name: "Индонезия", language_code: "ru", name_role: RegionName::NAME_ROLES[:preferred] }
      ]
    )
  end

  def region_for(external_uid)
    source_record_for(external_uid).region_source_link.region
  end

  def source_record_for(external_uid)
    Imports::SourceRecord.find_by!(import_source: source, external_uid:)
  end
end
