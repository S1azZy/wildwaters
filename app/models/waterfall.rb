class Waterfall < ApplicationRecord
  belongs_to :spot

  scope :with_public_spot_data, -> { includes(spot: :region).joins(:spot).merge(Spot.spot_type_waterfall.status_published) }
  scope :for_region_subtree, lambda { |region|
    where(spots: { region_id: region.descendant_closures.select(:descendant_id) })
  }
  scope :minimum_height, ->(height_meters) { where("waterfalls.height_meters >= ?", height_meters) }
  scope :with_plunge_pool, ->(value) { where(plunge_pool: value) }
  scope :with_approach_difficulty, ->(value) { where(approach_difficulty: value) }
  scope :within_bounds, lambda { |west:, south:, east:, north:|
    where(
      "ST_Intersects(spots.location, ST_MakeEnvelope(?, ?, ?, ?, 4326)::geography)",
      west,
      south,
      east,
      north
    )
  }
  scope :ordered_for_catalog, lambda {
    spot_table = Spot.arel_table

    order(
      spot_table[:published_at].desc.nulls_last,
      spot_table[:created_at].desc
    )
  }
  scope :with_spot_public_id, ->(public_id) { where(spots: { public_id: }) }

  validates :spot_id, uniqueness: true
  validates :height_meters, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
