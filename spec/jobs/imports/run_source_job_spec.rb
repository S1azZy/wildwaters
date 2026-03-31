require "rails_helper"

RSpec.describe Imports::RunSourceJob, type: :job do
  it "delegates region imports to the dataset interactor" do
    result = instance_double("ImportResult", failure?: false)
    records = [ { external_uid: "1643084" } ]

    expect(Imports::Regions::ImportDataset).to receive(:call).with(
      input: {
        source_key: "geonames_regions",
        mode: "full",
        initiated_by: "seed",
        records:
      }
    ).and_return(result)

    described_class.perform_now(
      source_key: "geonames_regions",
      mode: "full",
      initiated_by: "seed",
      records:
    )
  end

  it "raises a sanitized error when the import fails" do
    result = instance_double(
      "ImportResult",
      failure?: true,
      failure: {
        code: :source_disabled,
        errors: { source_key: [ "is disabled" ] }
      }
    )

    allow(Imports::Regions::ImportDataset).to receive(:call).and_return(result)

    expect do
      described_class.perform_now(
        source_key: "geonames_regions",
        mode: "full",
        initiated_by: "seed",
        records: []
      )
    end.to raise_error(StandardError, "Import failed for geonames_regions: source_disabled")
  end

  it "passes nil records for source-driven dump imports" do
    result = instance_double("ImportResult", failure?: false)

    expect(Imports::Regions::ImportDataset).to receive(:call).with(
      input: {
        source_key: "geonames_regions",
        mode: "full",
        initiated_by: "manual",
        records: nil
      }
    ).and_return(result)

    described_class.perform_now(
      source_key: "geonames_regions",
      mode: "full",
      initiated_by: "manual",
      records: nil
    )
  end
end
