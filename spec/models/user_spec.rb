require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:user_identities).dependent(:destroy) }
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    subject(:user) do
      described_class.new(
        primary_email: "user@example.com",
        role: "member",
        status: "active",
        locale: "en"
      )
    end

    it { is_expected.to validate_presence_of(:primary_email) }
    it { is_expected.to validate_inclusion_of(:role).in_array(User::ROLES) }
    it { is_expected.to validate_inclusion_of(:status).in_array(User::STATUSES) }
    it { is_expected.to validate_inclusion_of(:locale).in_array(I18n.available_locales.map(&:to_s)) }
  end

  it "normalizes primary_email before validation" do
    user = described_class.new(
      primary_email: "  USER@Example.COM ",
      role: "member",
      status: "active",
      locale: "en"
    )

    user.validate

    expect(user.primary_email).to eq("user@example.com")
  end

  it "enforces uniqueness of normalized primary_email" do
    create_user(primary_email: "user@example.com")

    duplicate = described_class.new(
      primary_email: " USER@example.com ",
      role: "member",
      status: "active",
      locale: "en"
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:primary_email]).to include("has already been taken")
  end

  def create_user(primary_email:)
    described_class.create!(
      primary_email:,
      role: "member",
      status: "active",
      locale: "en"
    )
  end
end
