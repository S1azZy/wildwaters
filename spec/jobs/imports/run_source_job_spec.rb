require "rails_helper"

class ImportResult
  def success?
  end

  def failure
  end
end

RSpec.describe Imports::RunSourceJob, type: :job do
  let(:import_interactor) { Imports::Regions::ImportDataset }

  it "delegates region imports to the dataset interactor" do
    records = [ { external_uid: "1643084" } ]
    allow(import_interactor).to receive(:call).and_return(instance_double(ImportResult, success?: true))

    described_class.perform_now(source_key: "geonames_regions", mode: "full", initiated_by: "seed", records:)

    expect(import_interactor).to have_received(:call).with(
      input: { source_key: "geonames_regions", mode: "full", initiated_by: "seed", records: }
    )
  end

  it "raises a sanitized error when the import fails" do
    allow(import_interactor).to receive(:call).and_return(instance_double(
      ImportResult,
      success?: false,
      failure: {
        code: :source_disabled,
        errors: { source_key: [ "is disabled" ] }
      }
    ))

    expect do
      described_class.perform_now(source_key: "geonames_regions", mode: "full", initiated_by: "seed", records: [])
    end.to raise_error(StandardError, "Import failed for geonames_regions: source_disabled")
  end

  it "passes nil records for source-driven dump imports" do
    allow(import_interactor).to receive(:call).and_return(instance_double(ImportResult, success?: true))

    described_class.perform_now(source_key: "geonames_regions", mode: "full", initiated_by: "manual", records: nil)

    expect(import_interactor).to have_received(:call).with(
      input: {
        source_key: "geonames_regions",
        mode: "full",
        initiated_by: "manual",
        records: nil
      }
    )
  end
end
