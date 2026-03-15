class Spot < ApplicationRecord
  PUBLIC_ID_LENGTH = 12

  SPOT_TYPES = {
    waterfall: "waterfall"
  }.freeze
  STATUSES = {
    draft: "draft",
    published: "published"
  }.freeze

  belongs_to :region
  has_one :waterfall, dependent: :destroy

  enum :spot_type, SPOT_TYPES, prefix: true
  enum :status, STATUSES, prefix: true

  scope :published, -> { where(status: STATUSES[:published]) }
  scope :waterfalls, -> { where(spot_type: SPOT_TYPES[:waterfall]) }

  normalizes :name, with: ->(value) { value.to_s.squish.presence }
  normalizes :slug, with: ->(value) { value.to_s.parameterize.presence }

  validates :public_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :region_id }
  validates :spot_type, presence: true, inclusion: { in: SPOT_TYPES.values }
  validates :status, presence: true, inclusion: { in: STATUSES.values }
  validates :location, presence: true

  before_validation :ensure_public_id, on: :create

  def to_param
    "#{public_id}-#{slug}"
  end

  def self.spatial_factory
    @spatial_factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
  end

  private

  def ensure_public_id
    self.public_id ||= Nanoid.generate(size: PUBLIC_ID_LENGTH)
  end
end
