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
    indonesia = create(:region, name: "Indonesia", slug: "indonesia", region_kind: "country", country_code: nil)
    create(:region_closure, ancestor: indonesia, descendant: indonesia, depth: 0)

    bali = create(
      :region,
      name: "Bali",
      slug: "bali",
      region_kind: "area",
      country_code: nil,
      parent: indonesia
    )
    create(:region_closure, ancestor: bali, descendant: bali, depth: 0)
    create(:region_closure, ancestor: indonesia, descendant: bali, depth: 1)

    expect { result }.to change(Region, :count).by(0)

    expect(Imports::RegionSourceLink.count).to eq(2)
    expect(Region.find_by!(slug: "bali").id).to eq(bali.id)
    expect(Region.find_by!(slug: "indonesia").id).to eq(indonesia.id)
  end

  it "supports canonical reparenting through the region-domain sync path" do
    result

    changed_dataset = [
      dataset.first,
      dataset.second.merge(parent_external_uid: nil)
    ]

    expect do
      described_class.call(input: input.merge(records: changed_dataset))
    end.not_to change(Region, :count)

    bali = Region.find_by!(slug: "bali")

    expect(bali.parent).to be_nil
    expect(bali.ancestor_closures.order(:depth).pluck(:ancestor_id, :depth)).to eq(
      [
        [ bali.id, 0 ]
      ]
    )
  end

  it "advances last_changed_at and writes snapshots when a source payload changes" do
    freeze_time do
      result
    end

    bali_source_record = Imports::SourceRecord.find_by!(external_uid: "1650535")
    first_changed_at = bali_source_record.last_changed_at

    travel 5.minutes do
      changed_dataset = [
        dataset.first,
        dataset.second.merge(
          alternate_names: [
            { language_code: "ru", name: "Остров Бали", name_role: "preferred" }
          ]
        )
      ]

      described_class.call(input: input.merge(records: changed_dataset))
    end

    bali_source_record.reload

    expect(bali_source_record.last_changed_at).to be > first_changed_at
    expect(bali_source_record.record_snapshots.order(:captured_at).count).to eq(2)
    expect(bali_source_record.record_snapshots.last.payload.fetch("alternate_names")).to eq(
      [
        {
          "language_code" => "ru",
          "name" => "Остров Бали",
          "name_role" => "preferred"
        }
      ]
    )
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

    it "imports through the existing pipeline when records are omitted" do
      expect(result).to be_success
      expect(Region.find_by!(slug: "bali").country_code).to eq("ID")
      expect(Region.find_by!(slug: "singaraja").parent.slug).to eq("bali")
      expect(RegionName.find_by!(name: "Бали").language_code).to eq("ru")
    end
  end
end
