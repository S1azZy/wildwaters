module Imports
  class RegionSourceLink < ApplicationRecord
    belongs_to :region, inverse_of: :source_links
    belongs_to :import_source_record, class_name: "Imports::SourceRecord", inverse_of: :region_source_link

    normalizes :match_strategy, with: ->(value) { value.to_s.strip.presence }

    validates :match_strategy, presence: true
    validates :confidence, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :matched_at, presence: true
    validates :import_source_record_id, uniqueness: true

    validate :single_primary_identity_per_region
    validate :canonical_source_required_for_primary_identity

    private

    def single_primary_identity_per_region
      return unless primary_identity?
      return unless region_id.present?
      return unless self.class.where(region_id:, primary_identity: true).where.not(id:).exists?

      errors.add(:region_id, "already has a primary identity")
    end

    def canonical_source_required_for_primary_identity
      return unless primary_identity?
      return if import_source_record&.import_source&.source_role_canonical_identity?

      errors.add(:primary_identity, "requires a canonical identity source")
    end
  end
end
