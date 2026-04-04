module Imports
  class SourceRecord < ApplicationRecord
    self.table_name = "import_source_records"

    STATUSES = {
      pending: "pending",
      matched: "matched",
      unresolved: "unresolved",
      failed: "failed",
      missing_upstream: "missing_upstream"
    }.freeze

    belongs_to :import_source, class_name: "Imports::Source", inverse_of: :source_records
    belongs_to :last_import_run, class_name: "Imports::Run", optional: true, inverse_of: :source_records

    has_one :region_source_link, class_name: "Imports::RegionSourceLink", foreign_key: :import_source_record_id, dependent: :destroy, inverse_of: :import_source_record
    has_many :record_snapshots, class_name: "Imports::RecordSnapshot", foreign_key: :import_source_record_id, dependent: :destroy, inverse_of: :import_source_record
    has_many :region_names, foreign_key: :import_source_record_id, dependent: :nullify, inverse_of: :import_source_record

    enum :status, STATUSES, prefix: true

    normalizes :record_kind, with: ->(value) { value.to_s.strip.presence }
    normalizes :external_uid, with: ->(value) { value.to_s.strip.presence }
    normalizes :external_url, with: ->(value) { value.to_s.strip.presence }

    validates :record_kind, presence: true
    validates :external_uid, presence: true, uniqueness: { scope: [ :import_source_id, :record_kind ] }
    validates :status, presence: true, inclusion: { in: STATUSES.values }
    validates :checksum, presence: true
  end
end
