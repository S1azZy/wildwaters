module Admin
  class UpdateUser < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:user_id).filled(:string)
        required(:attributes).hash do
          optional(:display_name).maybe(:string)
          optional(:role).filled(:string, included_in?: User::ROLES)
          optional(:status).filled(:string, included_in?: User::STATUSES)
        end
      end
    end

    def call
      user = yield find_user(input[:user_id])

      return Success(user:) if user.update(update_attributes)

      fail_with(code: :validation_error, errors: user.errors.to_hash)
    end

    private

    def find_user(user_id)
      user = User.find_by(id: user_id)

      return Success(user) if user

      fail_with(code: :user_not_found, errors: { user_id: [ "not found" ] })
    end

    def update_attributes
      ValidationContract.new.call(input).to_h.fetch(:attributes)
    end
  end
end
