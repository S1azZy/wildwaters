module Auth
  class ResetPassword < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:token).filled(:string)
        required(:password).filled(:string)
        required(:password_confirmation).filled(:string)
      end
    end

    def call
      in_transaction do
        user_identity = yield find_password_identity(input[:token])
        yield ensure_reset_token_is_active(user_identity)
        yield update_password(user_identity, input[:password], input[:password_confirmation])
        yield revoke_active_sessions(user_identity.user)

        Success(user: user_identity.user, user_identity:)
      end
    end

    private

    def find_password_identity(token)
      user_identity = UserIdentity.find_by_password_reset_token(token)

      return Success(user_identity) if user_identity

      fail_with(code: :invalid_token)
    end

    def ensure_reset_token_is_active(user_identity)
      return Success(user_identity) unless user_identity.password_reset_expired?

      fail_with(code: :invalid_token)
    end

    def update_password(user_identity, password, password_confirmation)
      user_identity.assign_attributes(
        password:,
        password_confirmation:,
        password_reset_token_digest: nil,
        password_reset_sent_at: nil
      )

      return Success(user_identity) if user_identity.save

      fail_with(code: :validation_error, errors: user_identity.errors.to_hash)
    end

    def revoke_active_sessions(user)
      Session.active.where(user:).update_all(revoked_at: Time.current, updated_at: Time.current)

      Success()
    end
  end
end
