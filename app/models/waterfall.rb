class Waterfall < ApplicationRecord
  belongs_to :spot

  scope :with_public_spot_data, -> { includes(spot: :region).joins(:spot).merge(Spot.spot_type_waterfall.status_published) }
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
