module Imports
  class RecordSnapshot < ApplicationRecord
    self.table_name = "import_record_snapshots"

    belongs_to :import_source_record, class_name: "Imports::SourceRecord", inverse_of: :record_snapshots
    belongs_to :import_run, class_name: "Imports::Run", inverse_of: :record_snapshots

    validates :checksum, presence: true
    validates :captured_at, presence: true
  end
end
