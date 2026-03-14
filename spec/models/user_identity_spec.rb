require "rails_helper"

RSpec.describe UserIdentity, type: :model do
  subject(:user_identity) { build_password_identity }

  let(:user) do
    User.create!(
      primary_email: "user@example.com",
      role: "member",
      status: "active",
      locale: "en"
    )
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_inclusion_of(:provider).in_array(Auth::Constants::PROVIDERS) }
  end

  it "normalizes email before validation" do
    identity = build_password_identity(email: " USER@Example.COM ")

    identity.validate

    expect(identity.email).to eq("user@example.com")
  end

  it "is valid for a password identity with password_digest" do
    expect(build_password_identity).to be_valid
  end

  it "requires a password_digest for password identities" do
    identity = described_class.new(user:, provider: Auth::Constants::PASSWORD)

    expect(identity).not_to be_valid
    expect(identity.errors[:password_digest]).to include("can't be blank")
  end

  it "requires provider_uid for external identities" do
    identity = described_class.new(user:, provider: Auth::Constants::GOOGLE, email: "user@example.com")

    expect(identity).not_to be_valid
    expect(identity.errors[:provider_uid]).to include("can't be blank")
  end

  it "prevents duplicate provider_uid within the same provider" do
    create_google_identity(provider_uid: "google-123")

    duplicate = described_class.new(
      user:,
      provider: Auth::Constants::GOOGLE,
      provider_uid: "google-123",
      email: "other@example.com"
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:provider_uid]).to include("has already been taken")
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
