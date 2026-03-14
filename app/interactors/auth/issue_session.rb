module Auth
  class IssueSession < ApplicationInteractor
    SESSION_TTL = 30.days

    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:user).filled(type?: User)
        required(:user_identity).filled(type?: UserIdentity)
      end
    end

    def call
      token = generate_token
      session_record = yield create_session(token)

      Success(session: session_record, token:)
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    def create_session(token)
      now = Time.current
      session_record = Session.new(
        user: input[:user],
        user_identity: input[:user_identity],
        authentication_method: input[:user_identity].provider,
        token_digest: Session.digest_token(token),
        ip_address: input[:ip_address],
        user_agent: input[:user_agent],
        last_seen_at: now,
        expires_at: now + SESSION_TTL
      )

      return Success(session_record) if session_record.save

      fail_with(code: :validation_error, errors: session_record.errors.to_hash)
    end

    def generate_token
      SecureRandom.urlsafe_base64(48)
    end
  end
end
