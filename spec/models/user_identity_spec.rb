require "rails_helper"

RSpec.describe UserIdentity, type: :model do
  subject(:user_identity) { build_password_identity }

  let(:user) { create(:user, primary_email: "user@example.com") }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_inclusion_of(:provider).in_array(Auth::Constants::PROVIDERS) }
    it { is_expected.to validate_uniqueness_of(:password_reset_token_digest).allow_nil }
  end

  it "normalizes email before validation" do
    user_identity = build_password_identity(email: " USER@Example.COM ")

    user_identity.validate

    expect(user_identity.email).to eq("user@example.com")
  end

  it "is valid for a password identity with password_digest" do
    expect(build_password_identity).to be_valid
  end

  it "requires a password_digest for password identities" do
    user_identity = described_class.new(user:, provider: Auth::Constants::PASSWORD, email: "user@example.com")

    expect(user_identity).not_to be_valid
    expect(user_identity.errors[:password_digest]).to include("can't be blank")
  end

  it "requires provider_uid for external identities" do
    user_identity = described_class.new(user:, provider: Auth::Constants::GOOGLE, email: "user@example.com")

    expect(user_identity).not_to be_valid
    expect(user_identity.errors[:provider_uid]).to include("can't be blank")
  end

  it "prevents duplicate provider_uid within the same provider" do
    create_google_identity(provider_uid: "google-123")

    user_identity = described_class.new(
      user:,
      provider: Auth::Constants::GOOGLE,
      provider_uid: "google-123",
      email: "other@example.com"
    )

    expect(user_identity).not_to be_valid
    expect(user_identity.errors[:provider_uid]).to include("has already been taken")
  end

  describe "#password_reset_expired?" do
    subject(:password_reset_expired?) { user_identity.password_reset_expired? }

    around { |example| freeze_time(&example) }

    context "when the reset timestamp is blank" do
      let(:user_identity) { build(:user_identity, password_reset_sent_at: nil) }

      it { is_expected.to be(true) }
    end

    context "when the reset timestamp is still valid" do
      let(:user_identity) { build(:user_identity, password_reset_sent_at: 10.minutes.ago) }

      it { is_expected.to be(false) }
    end

    context "when the reset timestamp is expired" do
      let(:user_identity) { build(:user_identity, password_reset_sent_at: 31.minutes.ago) }

      it { is_expected.to be(true) }
    end
  end

  def create_google_identity(provider_uid:)
    described_class.create!(
      user:,
      provider: Auth::Constants::GOOGLE,
      provider_uid:,
      email: "user@example.com"
    )
  end

  def build_password_identity(email: "user@example.com")
    described_class.new(
      user:,
      provider: Auth::Constants::PASSWORD,
      email:,
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end
end
