class RegionName < ApplicationRecord
  NAME_ROLES = {
    primary: "primary",
    official: "official",
    preferred: "preferred",
    native: "native",
    alias: "alias",
    ascii: "ascii"
  }.freeze

  belongs_to :region
  belongs_to :import_source_record, class_name: "Imports::SourceRecord", optional: true

  enum :name_role, NAME_ROLES, prefix: true

  normalizes :language_code, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :name, with: ->(value) { value.to_s.squish.presence }
  normalizes :normalized_name, with: ->(value) { RegionName.normalize_name(value) }

  validates :name, presence: true
  validates :normalized_name, presence: true
  validates :name_role, presence: true, inclusion: { in: NAME_ROLES.values }
  validates :normalized_name, uniqueness: { scope: [ :region_id, :language_code, :name_role ] }

  before_validation :ensure_normalized_name

  def self.normalize_name(value)
    value.to_s.unicode_normalize(:nfc).downcase.squish.presence
  end

  private

  def ensure_normalized_name
    self.normalized_name = self.class.normalize_name(name) if normalized_name.blank? && name.present?
  end
end
