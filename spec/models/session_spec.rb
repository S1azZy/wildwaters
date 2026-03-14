require "rails_helper"

RSpec.describe Session, type: :model do
  subject(:session_record) { build_session }

  let(:user) do
    User.create!(
      primary_email: "user@example.com",
      role: "member",
      status: "active",
      locale: "en"
    )
  end
  let(:user_identity) do
    UserIdentity.create!(
      user:,
      provider: Auth::Constants::PASSWORD,
      email: "user@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:user_identity) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:authentication_method) }
    it { is_expected.to validate_inclusion_of(:authentication_method).in_array(Auth::Constants::PROVIDERS) }
    it { is_expected.to validate_presence_of(:token_digest) }
    it { is_expected.to validate_presence_of(:last_seen_at) }
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  it "is active when not revoked and not expired" do
    expect(build_session).to be_active
  end

  it "is not active when revoked" do
    session = build_session(revoked_at: Time.current)

    expect(session).not_to be_active
    expect(session).to be_revoked
  end

  it "is not active when expired" do
    session = build_session(expires_at: 1.minute.ago)

    expect(session).not_to be_active
    expect(session).to be_expired
  end

  def build_session(expires_at: 1.day.from_now, revoked_at: nil)
    described_class.new(
      user:,
      user_identity:,
      authentication_method: Auth::Constants::PASSWORD,
      token_digest: Session.digest_token(SecureRandom.urlsafe_base64(48)),
      last_seen_at: Time.current,
      expires_at:,
      revoked_at:
    )
  end
end
