return if Rails.env.production?

GEONAMES_REGION_SOURCE_KEY = "geonames_regions".freeze
GEONAMES_REGION_RECORDS = [
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
  },
  {
    record_kind: "region",
    external_uid: "1645528",
    external_url: "https://www.geonames.org/1645528",
    name: "North Bali",
    ascii_name: "North Bali",
    region_kind: "locality",
    country_code: "ID",
    parent_external_uid: "1650535",
    latitude: -8.1694,
    longitude: 115.1806,
    alternate_names: [
      { language_code: "ru", name: "Северный Бали", name_role: "preferred" }
    ]
  }
].freeze

def seed_geonames_regions
  source = Imports::Source.find_or_initialize_by(key: GEONAMES_REGION_SOURCE_KEY)
  source.assign_attributes(
    target_kind: "region",
    source_role: Imports::Source::SOURCE_ROLES[:canonical_identity],
    fetch_mode: Imports::Source::FETCH_MODES[:manual_file],
    enabled: true,
    license_key: "geonames",
    license_url: "https://www.geonames.org/export/",
    attribution_text: "GeoNames",
    display_policy: Imports::Source::DISPLAY_POLICIES[:public_display_allowed],
    config: { "seeded" => true }
  )
  source.save!

  Imports::RunSourceJob.perform_now(
    source_key: source.key,
    mode: Imports::Run::MODES[:full],
    initiated_by: "seed",
    records: GEONAMES_REGION_RECORDS
  )
end

def find_imported_region!(source_key:, external_uid:)
  Region
    .joins(source_links: { import_source_record: :import_source })
    .find_by!(
      import_sources: { key: source_key },
      import_source_records: { external_uid: external_uid },
      region_source_links: { primary_identity: true }
    )
end

def seed_waterfall(region:, slug:, name:, summary:, description:, latitude:, longitude:, height_meters:, plunge_pool:, flow_seasonality:, approach_difficulty:, published:)
  spot = Spot.find_or_initialize_by(region:, slug:)
  spot.assign_attributes(
    spot_type: Spot::SPOT_TYPES[:waterfall],
    name:,
    summary:,
    description:,
    status: published ? Spot::STATUSES[:published] : Spot::STATUSES[:draft],
    published_at: published ? Time.current : nil,
    location: Spot.spatial_factory.point(longitude, latitude)
  )
  spot.save!

  waterfall = spot.waterfall || spot.build_waterfall
  waterfall.assign_attributes(
    height_meters:,
    plunge_pool:,
    flow_seasonality:,
    approach_difficulty:
  )
  waterfall.save!
end

seed_geonames_regions

bali = find_imported_region!(source_key: GEONAMES_REGION_SOURCE_KEY, external_uid: "1650535")
north_bali = find_imported_region!(source_key: GEONAMES_REGION_SOURCE_KEY, external_uid: "1645528")

seed_waterfall(
  region: north_bali,
  slug: "sekumpul-waterfall",
  name: "Sekumpul Waterfall",
  summary: "Twin jungle cascades that feel like Bali turned up to eleven.",
  description: "A dramatic multi-stream waterfall reached by a steep trail through North Bali's lush valley.",
  latitude: -8.1694,
  longitude: 115.1806,
  height_meters: 80.0,
  plunge_pool: true,
  flow_seasonality: "year_round",
  approach_difficulty: "moderate",
  published: true
)
seed_waterfall(
  region: north_bali,
  slug: "gitgit-waterfall",
  name: "Gitgit Waterfall",
  summary: "An accessible cascade popular for quick day trips from central Bali.",
  description: "One of Bali's classic roadside waterfall stops with an easy approach and refreshing spray.",
  latitude: -8.1883,
  longitude: 115.1415,
  height_meters: 35.0,
  plunge_pool: false,
  flow_seasonality: "year_round",
  approach_difficulty: "easy",
  published: true
)
seed_waterfall(
  region: bali,
  slug: "hidden-falls",
  name: "Hidden Falls",
  summary: "Draft demo entry for future editorial work.",
  description: "This draft spot exists to prove that public catalog pages only show published waterfalls.",
  latitude: -8.4095,
  longitude: 115.1889,
  height_meters: 22.0,
  plunge_pool: false,
  flow_seasonality: "seasonal",
  approach_difficulty: "moderate",
  published: false
)
