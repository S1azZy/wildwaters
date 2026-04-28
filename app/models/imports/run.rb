module Imports
  class Run < ApplicationRecord
    MODES = {
      full: "full",
      incremental: "incremental",
      backfill: "backfill",
      replay: "replay"
    }.freeze
    STATUSES = {
      queued: "queued",
      running: "running",
      succeeded: "succeeded",
      failed: "failed",
      partially_failed: "partially_failed",
      cancelled: "cancelled"
    }.freeze

    belongs_to :import_source, class_name: "Imports::Source", inverse_of: :runs
    has_many :items, class_name: "Imports::RunItem", foreign_key: :import_run_id, dependent: :destroy, inverse_of: :import_run
    has_many :source_records, class_name: "Imports::SourceRecord", foreign_key: :last_import_run_id, dependent: :nullify, inverse_of: :last_import_run
    has_many :record_snapshots, class_name: "Imports::RecordSnapshot", foreign_key: :import_run_id, dependent: :restrict_with_exception, inverse_of: :import_run

    enum :mode, MODES, prefix: true
    enum :status, STATUSES, prefix: true

    validates :mode, presence: true, inclusion: { in: MODES.values }
    validates :status, presence: true, inclusion: { in: STATUSES.values }
    validates :initiated_by, presence: true

    scope :active, -> { where(status: [ STATUSES[:queued], STATUSES[:running] ]) }
  end
end
