def find_or_create_region(name:, region_type:, external_ref:, parent_id: nil)
  existing_region = Region.find_by(external_ref:)
  return existing_region if existing_region

  result = Regions::CreateRegion.call(
    input: {
      name:,
      region_type:,
      parent_id:,
      external_ref:
    }
  )

  result.value![:region]
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

macroregion = find_or_create_region(
  name: "Southeast Asia",
  region_type: Region::REGION_TYPES[:macroregion],
  external_ref: "seed:southeast-asia"
)
country = find_or_create_region(
  name: "Indonesia",
  region_type: Region::REGION_TYPES[:country],
  parent_id: macroregion.id,
  external_ref: "seed:indonesia"
)
bali = find_or_create_region(
  name: "Bali",
  region_type: Region::REGION_TYPES[:admin_area],
  parent_id: country.id,
  external_ref: "seed:bali"
)
north_bali = find_or_create_region(
  name: "North Bali",
  region_type: Region::REGION_TYPES[:locality],
  parent_id: bali.id,
  external_ref: "seed:north-bali"
)

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
