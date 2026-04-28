module Imports
  class Source < ApplicationRecord
    SOURCE_ROLES = {
      canonical_identity: "canonical_identity",
      name_enrichment: "name_enrichment",
      geometry_enrichment: "geometry_enrichment",
      analysis_only: "analysis_only"
    }.freeze
    FETCH_MODES = {
      dump: "dump",
      api: "api",
      scrape: "scrape",
      manual_file: "manual_file"
    }.freeze
    DISPLAY_POLICIES = {
      public_display_allowed: "public_display_allowed",
      derived_only: "derived_only",
      internal_only: "internal_only"
    }.freeze

    has_many :runs, class_name: "Imports::Run", foreign_key: :import_source_id, dependent: :destroy, inverse_of: :import_source
    has_many :source_records, class_name: "Imports::SourceRecord", foreign_key: :import_source_id, dependent: :destroy, inverse_of: :import_source

    enum :source_role, SOURCE_ROLES, prefix: true
    enum :fetch_mode, FETCH_MODES, prefix: true
    enum :display_policy, DISPLAY_POLICIES, prefix: true

    normalizes :key, with: ->(value) { value.to_s.strip.presence }
    normalizes :target_kind, with: ->(value) { value.to_s.strip.presence }

    validates :key, presence: true, uniqueness: true
    validates :target_kind, presence: true
    validates :source_role, presence: true, inclusion: { in: SOURCE_ROLES.values }
    validates :fetch_mode, presence: true, inclusion: { in: FETCH_MODES.values }
    validates :license_key, presence: true
    validates :display_policy, presence: true, inclusion: { in: DISPLAY_POLICIES.values }
  end
end
