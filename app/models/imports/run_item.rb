module Imports
  class RunItem < ApplicationRecord
    self.table_name = "import_run_items"

    STATUSES = {
      queued: "queued",
      running: "running",
      succeeded: "succeeded",
      failed: "failed",
      cancelled: "cancelled"
    }.freeze

    belongs_to :import_run, class_name: "Imports::Run", inverse_of: :items

    enum :status, STATUSES, prefix: true

    validates :item_kind, presence: true
    validates :item_key, presence: true
    validates :status, presence: true, inclusion: { in: STATUSES.values }
    validates :attempts_count, numericality: { greater_than_or_equal_to: 0 }
  end
end
