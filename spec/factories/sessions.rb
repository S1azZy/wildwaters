FactoryBot.define do
  factory :session do
    user { create(:user) }
    user_identity { create(:user_identity, user:) }
    authentication_method { user_identity.provider }
    token_digest { Session.digest_token(SecureRandom.urlsafe_base64(48)) }
    last_seen_at { Time.current }
    expires_at { 30.days.from_now }
    revoked_at { nil }
  end
end
