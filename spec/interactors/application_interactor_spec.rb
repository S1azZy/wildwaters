# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationInteractor do
  subject(:result) { interactor_class.call(input: { email: }) }

  let(:email) { "user@example.com" }
  let(:contract_class) do
    Class.new(ApplicationContract) do
      params do
        required(:email).filled(:string)
      end

      rule(:email) do
        key.failure("must contain @") unless value.include?("@")
      end
    end
  end
  let(:interactor_class) do
    interactor = Class.new(ApplicationInteractor) do
      option :input

      def call
        Success(email: input[:email])
      end
    end

    stub_const("SpecTestValidationContract", contract_class)
    stub_const("SpecTestInteractor", interactor)
    stub_const("SpecTestInteractor::ValidationContract", SpecTestValidationContract)

    SpecTestInteractor
  end

  it "returns success for valid input" do
    expect(result).to be_success
    expect(result.value!).to eq(email:)
  end

  context "when validation fails" do
    let(:email) { "invalid-email" }

    it "returns a structured validation failure" do
      expect(result).to be_failure
      expect(result.failure).to eq(
        code: :validation_error,
        errors: { email: [ "must contain @" ] }
      )
    end
  end
end
