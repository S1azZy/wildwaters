class Waterfall < ApplicationRecord
  belongs_to :spot

  scope :with_public_spot_data, -> { includes(spot: :region).joins(:spot).merge(Spot.waterfalls.published) }
  scope :ordered_for_catalog, -> { order(Arel.sql("spots.published_at DESC NULLS LAST, spots.created_at DESC")) }
  scope :with_spot_public_id, ->(public_id) { where(spots: { public_id: }) }

  validates :spot_id, uniqueness: true
  validates :height_meters, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
