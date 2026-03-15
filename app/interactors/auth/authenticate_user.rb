module Auth
  class AuthenticateUser < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:email).filled(:string)
        required(:password).filled(:string)
      end
    end

    def call
      user_identity = yield find_password_identity(input[:email])
      yield authenticate_password(user_identity, input[:password])
      yield ensure_active_user(user_identity.user)

      Success(user: user_identity.user, user_identity:)
    end

    private

    def find_password_identity(email)
      user_identity = UserIdentity.password.find_by(email: EmailNormalizer.normalize(email))

      return Success(user_identity) if user_identity

      fail_with(code: :invalid_credentials)
    end

    def authenticate_password(user_identity, password)
      return Success(user_identity) if user_identity.authenticate(password)

      fail_with(code: :invalid_credentials)
    end

    def ensure_active_user(user)
      return Success(user) unless user.suspended?

      fail_with(code: :account_suspended)
    end
  end
end
