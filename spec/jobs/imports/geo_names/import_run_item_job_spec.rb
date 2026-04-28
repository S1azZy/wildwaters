require "rails_helper"

class ProcessRunItemResult
  def success?
  end

  def failure
  end
end

RSpec.describe Imports::GeoNames::ImportRunItemJob, type: :job do
  let(:import_interactor) { Imports::GeoNames::ProcessRunItem }

  it "delegates item import to the interactor" do
    allow(import_interactor).to receive(:call).and_return(instance_double(ProcessRunItemResult, success?: true))

    described_class.perform_now(123)

    expect(import_interactor).to have_received(:call).with(input: { import_run_item_id: 123 })
  end

  it "raises a sanitized error when the interactor fails" do
    allow(import_interactor).to receive(:call).and_return(instance_double(
      ProcessRunItemResult,
      success?: false,
      failure: {
        code: :run_item_not_found,
        errors: { import_run_item_id: [ "not found" ] }
      }
    ))

    expect do
      described_class.perform_now(123)
    end.to raise_error(StandardError, "GeoNames import run item failed: run_item_not_found")
  end
end
