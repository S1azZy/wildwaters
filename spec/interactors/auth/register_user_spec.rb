require "rails_helper"

RSpec.describe Auth::RegisterUser, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      email:,
      password: "Password123!",
      password_confirmation:,
      locale:
    }
  end
  let(:email) { " USER@example.com " }
  let(:password_confirmation) { "Password123!" }
  let(:locale) { "ru" }

  it "returns success" do
    expect(result).to be_success
  end

  it "creates a user and password identity" do
    expect { result }.to change(User, :count).by(1)
      .and change(UserIdentity, :count).by(1)
  end

  it "returns the created records" do
    expect(result.value!).to include(
      user: have_attributes(primary_email: "user@example.com", locale: "ru"),
      user_identity: have_attributes(provider: Auth::Constants::PASSWORD)
    )
  end

  context "when the password identity is invalid" do
    let(:email) { "user@example.com" }
    let(:password_confirmation) { "Mismatch123!" }
    let(:locale) { "en" }

    it "returns failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
    end

    it "rolls back the user" do
      expect { result }.not_to change { [ User.count, UserIdentity.count ] }
    end
  end
end
