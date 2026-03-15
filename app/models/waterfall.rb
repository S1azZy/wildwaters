class Waterfall < ApplicationRecord
  belongs_to :spot

  validates :spot_id, uniqueness: true
  validates :height_meters, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
