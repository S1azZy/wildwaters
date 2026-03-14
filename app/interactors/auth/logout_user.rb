module Auth
  class LogoutUser < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:session).filled(type?: Session)
      end
    end

    def call
      session = input[:session]
      yield revoke_session(session)

      Success(session:)
    end

    private

    def revoke_session(session)
      return Success(session) if session.revoked?

      safe_call { session.revoke! }
        .or { |error| fail_with(code: :logout_failed, errors: { session: [ error.message ] }) }
    end
  end
end
