require "rails_helper"

RSpec.describe Imports::Regions::ImportDataset, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let!(:source) do
    create(
      :imports_source,
      key: "geonames_regions",
      target_kind: "region",
      source_role: "canonical_identity",
      fetch_mode: "manual_file",
      license_key: "geonames",
      display_policy: "public_display_allowed"
    )
  end
  let(:input) do
    {
      source_key: source.key,
      mode: "full",
      initiated_by: "seed",
      records: dataset
    }
  end
  let(:dataset) do
    [
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
        alternate_names: [
          { language_code: "ru", name: "Индонезия", name_role: "preferred" }
        ]
      },
      {
        record_kind: "region",
        external_uid: "1650535",
        external_url: "https://www.geonames.org/1650535",
        name: "Bali",
        ascii_name: "Bali",
        region_kind: "area",
        country_code: "ID",
        parent_external_uid: "1643084",
        latitude: -8.4095,
        longitude: 115.1889,
        alternate_names: [
          { language_code: "ru", name: "Бали", name_role: "preferred" }
        ]
      }
    ]
  end

  it "returns success" do
    expect(result).to be_success
  end

  it "creates regions, provenance records, links, and localized names" do
    expect { result }.to change(Region, :count).by(2)
      .and change(Imports::Run, :count).by(1)
      .and change(Imports::SourceRecord, :count).by(2)
      .and change(Imports::RegionSourceLink, :count).by(2)
      .and change(RegionName, :count).by(6)
  end

  it "stores the canonical hierarchy and centers" do
    result

    indonesia = Region.find_by!(slug: "indonesia")
    bali = Region.find_by!(slug: "bali")

    expect(bali.parent).to eq(indonesia)
    expect(indonesia.country_code).to eq("ID")
    expect(bali.region_kind).to eq("area")
    expect(bali.center).to be_present
  end

  it "persists alternate names for search readiness" do
    result

    bali = Region.find_by!(slug: "bali")

    expect(bali.region_names.find_by!(language_code: "ru", name: "Бали")).to have_attributes(
      name_role: "preferred",
      searchable: true
    )
  end

  it "is idempotent on repeated imports" do
    result

    expect { described_class.call(input:) }.to change(Imports::Run, :count).by(1)
    expect([ Region.count, Imports::SourceRecord.count, Imports::RegionSourceLink.count, RegionName.count ]).to eq([ 2, 2, 2, 6 ])
    expect(Imports::RecordSnapshot.count).to eq(2)
  end

  it "attaches to an existing structurally matching region tree without creating duplicates" do
    indonesia, bali = seed_structurally_matching_regions

    expect { result }.not_to change(Region, :count)

    expect(Imports::RegionSourceLink.count).to eq(2)
    expect(Region.find_by!(slug: "bali").id).to eq(bali.id)
    expect(Region.find_by!(slug: "indonesia").id).to eq(indonesia.id)
  end

  it "supports canonical reparenting through the region-domain sync path" do
    result
    expect { reimport_bali_without_parent }.not_to change(Region, :count)

    expect(bali_region.reload.parent).to be_nil
    expect(bali_region.ancestor_closures.order(:depth).pluck(:ancestor_id, :depth)).to eq([ [ bali_region.id, 0 ] ])
  end

  it "advances last_changed_at and writes snapshots when a source payload changes" do
    freeze_time do
      result
    end

    first_changed_at = bali_source_record.last_changed_at
    update_bali_alternate_names

    expect(bali_source_record.reload.last_changed_at).to be > first_changed_at
    expect(bali_source_record.record_snapshots.order(:captured_at).count).to eq(2)
    expect(bali_source_record.record_snapshots.last.payload.fetch("alternate_names")).to eq([ changed_bali_alternate_name ])
  end

  it "marks records as missing upstream on a repeated full import without deleting matched regions" do
    result

    bali_source_record = Imports::SourceRecord.find_by!(external_uid: "1650535")
    bali_region = bali_source_record.region_source_link.region

    rerun_result = described_class.call(input: input.merge(records: [ dataset.first ]))

    expect(rerun_result).to be_success
    expect(bali_source_record.reload).to have_attributes(
      status: Imports::SourceRecord::STATUSES[:missing_upstream],
      last_import_run: rerun_result.value!.fetch(:run)
    )
    expect(bali_source_record.region_source_link.region).to eq(bali_region)
    expect(Region.find(bali_region.id)).to eq(bali_region)
  end

  it "does not mark omitted records as missing on incremental reruns" do
    result

    bali_source_record = Imports::SourceRecord.find_by!(external_uid: "1650535")

    rerun_result = described_class.call(input: input.merge(mode: "incremental", records: [ dataset.first ]))

    expect(rerun_result).to be_success
    expect(bali_source_record.reload.status).to eq(Imports::SourceRecord::STATUSES[:matched])
  end

  it "limits missing-upstream reconciliation to the requested country shard" do
    old_ad_record = create_old_source_record(external_uid: "old-ad", country_code: "AD")
    old_fr_record = create_old_source_record(external_uid: "old-fr", country_code: "FR")

    expect(import_ad_shard).to be_success
    expect(old_ad_record.reload.status).to eq(Imports::SourceRecord::STATUSES[:missing_upstream])
    expect(old_fr_record.reload.status).to eq(Imports::SourceRecord::STATUSES[:matched])
  end

  context "when the source is disabled" do
    before do
      source.update!(enabled: false)
    end

    it "returns a disabled-source failure without creating a run" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:source_disabled)
      expect(Imports::Run.count).to eq(0)
    end
  end

  context "when the source does not exist" do
    let(:input) { super().merge(source_key: "missing") }

    it "returns failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:source_not_found)
    end
  end

  context "when loading records from configured GeoNames dump files" do
    let(:all_countries_path) { Rails.root.join("tmp/geonames_all_countries_test.txt") }
    let(:alternate_names_path) { Rails.root.join("tmp/geonames_alternate_names_test.txt") }
    let(:input) do
      {
        source_key: source.key,
        mode: "full",
        initiated_by: "manual"
      }
    end

    before do
      source.update!(
        fetch_mode: "dump",
        config: {
          "all_countries_path" => all_countries_path.to_s,
          "alternate_names_path" => alternate_names_path.to_s,
          "country_codes" => [ "ID" ],
          "languages" => [ "en", "ru" ]
        }
      )

      all_countries_path.dirname.mkpath
      all_countries_path.write(
        [
          "1643084\tIndonesia\tIndonesia\tIndonesia\t-2.5\t118.0\tA\tPCLI\tID\t\t\t\t\t\t0\t\t\tAsia/Jakarta\t2024-01-01",
          "1650535\tBali\tBali\tBali\t-8.4095\t115.1889\tA\tADM1\tID\t\t02\t\t\t\t0\t\t\tAsia/Jakarta\t2024-01-01",
          "1651111\tSingaraja\tSingaraja\tSingaraja\t-8.112\t115.088\tP\tPPL\tID\t\t02\t\t\t\t0\t\t\tAsia/Jakarta\t2024-01-01"
        ].join("\n")
      )
      alternate_names_path.write(
        [
          "1\t1650535\tru\tБали\t1\t0\t0\t0\t\t",
          "2\t1651111\tru\tСингараджа\t0\t0\t0\t0\t\t"
        ].join("\n")
      )
    end

    after do
      all_countries_path.delete if all_countries_path.exist?
      alternate_names_path.delete if alternate_names_path.exist?
    end

    it "imports the default MVP feature-code slice through the existing pipeline when records are omitted" do
      expect(result).to be_success
      expect(Region.find_by!(slug: "bali").country_code).to eq("ID")
      expect(RegionName.find_by!(name: "Бали").language_code).to eq("ru")
      expect(Region.find_by(slug: "singaraja")).to be_nil
    end
  end

  context "when loading the official GeoNames Andorra fixtures" do
    let(:expected_record_count) { 15 }
    let(:input) do
      {
        source_key: source.key,
        mode: "full",
        initiated_by: "fixture"
      }
    end
    let(:country) { Imports::SourceRecord.find_by!(external_uid: "3041565").region_source_link.region }
    let(:ordino_area) { Imports::SourceRecord.find_by!(external_uid: "3039676").region_source_link.region }
    let(:ordino_locality) { Imports::SourceRecord.find_by!(external_uid: "3039678").region_source_link.region }

    before do
      source.update!(
        fetch_mode: "dump",
        config: {
          "all_countries_path" => "spec/fixtures/imports/geonames/country_AD.txt",
          "alternate_names_path" => "spec/fixtures/imports/geonames/alternate_names_AD.txt",
          "country_codes" => [ "AD" ],
          "languages" => [ "en", "ru", "ca", "fr", "es" ]
        }
      )
    end

    it "imports the real fixture through the existing dump pipeline" do
      expect { result }.to change(Region, :count).by(expected_record_count)
        .and change(Imports::SourceRecord, :count).by(expected_record_count)
        .and change(Imports::RegionSourceLink, :count).by(expected_record_count)
    end

    it "preserves the expected Andorra hierarchy from the official fixture" do
      result

      expect(country).to have_attributes(
        name: "Principality of Andorra",
        region_kind: "country",
        parent: nil
      )
      expect(ordino_area.parent).to eq(country)
      expect(ordino_area.region_kind).to eq("area")
      expect(ordino_locality.parent).to eq(ordino_area)
      expect(ordino_locality.region_kind).to eq("locality")
      expect(andorra_ru_name).to have_attributes(name_role: "preferred", searchable: true)
    end

    it "remains idempotent on repeated runs of the real fixture" do
      result

      expect { described_class.call(input:) }.to change(Imports::Run, :count).by(1)
      expect([ Region.count, Imports::SourceRecord.count, Imports::RegionSourceLink.count ]).to eq(
        [ expected_record_count, expected_record_count, expected_record_count ]
      )
      expect(Imports::SourceRecord.where(status: Imports::SourceRecord::STATUSES[:missing_upstream]).count).to eq(0)
    end

    it "accepts an explicit nil records value for dump-driven execution paths" do
      expect(
        described_class.call(input: input.merge(records: nil))
      ).to be_success
    end
  end

  def seed_structurally_matching_regions
    indonesia = create(:region, name: "Indonesia", slug: "indonesia", region_kind: "country", country_code: nil)
    create(:region_closure, ancestor: indonesia, descendant: indonesia, depth: 0)

    bali = create(:region, name: "Bali", slug: "bali", region_kind: "area", country_code: nil, parent: indonesia)
    create(:region_closure, ancestor: bali, descendant: bali, depth: 0)
    create(:region_closure, ancestor: indonesia, descendant: bali, depth: 1)

    [ indonesia, bali ]
  end

  def reimport_bali_without_parent
    described_class.call(input: input.merge(records: [ dataset.first, dataset.second.merge(parent_external_uid: nil) ]))
  end

  def update_bali_alternate_names
    travel 5.minutes do
      described_class.call(input: input.merge(records: [ dataset.first, dataset.second.merge(alternate_names: [ changed_bali_alternate_name.symbolize_keys ]) ]))
    end
  end

  def changed_bali_alternate_name
    {
      "language_code" => "ru",
      "name" => "Остров Бали",
      "name_role" => "preferred"
    }
  end

  def bali_source_record
    Imports::SourceRecord.find_by!(external_uid: "1650535")
  end

  def bali_region
    Region.find_by!(slug: "bali")
  end

  def create_old_source_record(external_uid:, country_code:)
    create(
      :imports_source_record,
      import_source: source,
      last_import_run: nil,
      external_uid:,
      status: Imports::SourceRecord::STATUSES[:matched],
      normalized_payload: { "country_code" => country_code }
    )
  end

  def import_ad_shard
    shard_run = create(:imports_run, import_source: source, mode: Imports::Run::MODES[:full])

    described_class.call(
      input: input.merge(
        import_run_id: shard_run.id,
        reconciliation_country_code: "AD",
        records: [ andorra_country_record ]
      )
    )
  end

  def andorra_country_record
    {
      record_kind: "region",
      external_uid: "3041565",
      external_url: "https://www.geonames.org/3041565",
      name: "Principality of Andorra",
      ascii_name: "Andorra",
      region_kind: "country",
      country_code: "AD",
      parent_external_uid: nil,
      latitude: 42.5,
      longitude: 1.5,
      alternate_names: []
    }
  end

  def andorra_ru_name
    country.region_names.find_by!(language_code: "ru", name: "Андорра")
  end
end
