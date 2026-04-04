class Region < ApplicationRecord
  PUBLIC_ID_LENGTH = 12

  REGION_KINDS = {
    country: "country",
    area: "area",
    locality: "locality",
    park: "park",
    custom: "custom"
  }.freeze
  STATUSES = {
    active: "active",
    archived: "archived"
  }.freeze

  belongs_to :parent, class_name: "Region", optional: true, inverse_of: :children

  has_many :children, class_name: "Region", foreign_key: :parent_id, inverse_of: :parent, dependent: :nullify
  has_many :spots, dependent: :restrict_with_exception
  has_many :ancestor_closures, class_name: "RegionClosure", foreign_key: :descendant_id, inverse_of: :descendant, dependent: :destroy
  has_many :descendant_closures, class_name: "RegionClosure", foreign_key: :ancestor_id, inverse_of: :ancestor, dependent: :destroy
  has_many :region_names, dependent: :destroy
  has_many :source_links, class_name: "Imports::RegionSourceLink", dependent: :destroy

  has_many :ancestors, -> { order("region_closures.depth ASC") }, through: :ancestor_closures, source: :ancestor
  has_many :descendants, -> { order("region_closures.depth ASC") }, through: :descendant_closures, source: :descendant

  enum :region_kind, REGION_KINDS, prefix: true
  enum :status, STATUSES, prefix: true

  scope :ordered_for_explore, -> { status_active.order(:name) }

  normalizes :name, with: ->(value) { value.to_s.squish.presence }
  normalizes :slug, with: ->(value) { value.to_s.parameterize.presence }
  normalizes :country_code, with: ->(value) { value.to_s.strip.upcase.presence }

  validates :public_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :parent_id }
  validates :region_kind, presence: true, inclusion: { in: REGION_KINDS.values }
  validates :status, presence: true, inclusion: { in: STATUSES.values }
  validates :country_code, format: { with: /\A[A-Z]{2}\z/ }, allow_nil: true

  before_validation :ensure_public_id, on: :create

  def self.spatial_factory
    @spatial_factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
  end

  private

  def ensure_public_id
    self.public_id ||= Nanoid.generate(size: PUBLIC_ID_LENGTH)
  end
end
