# frozen_string_literal: true

class ApplicationInteractor < Yabi::BaseInteractor
  def validate_contract(validation_contract)
    return Success() unless validation_contract

    validation_contract.new.call(**attributes_for_contract[:input])
  end

  def log_warning_and_return_failure(validation)
    errors = validation.respond_to?(:errors) ? validation.errors.to_h : validation

    fail_with(code: :validation_error, errors:)
  end

  private

  def fail_with(code:, errors: {})
    Failure(code:, errors:)
  end
end
