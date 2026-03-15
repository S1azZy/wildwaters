class RegionClosure < ApplicationRecord
  self.primary_key = %i[ancestor_id descendant_id]

  belongs_to :ancestor, class_name: "Region", inverse_of: :descendant_closures
  belongs_to :descendant, class_name: "Region", inverse_of: :ancestor_closures

  validates :depth, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
