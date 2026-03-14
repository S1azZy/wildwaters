require "rails_helper"

RSpec.describe Auth::AuthenticateUser, type: :interactor do
  it "authenticates a password identity by normalized email" do
    user_identity = create(:user_identity, email: "user@example.com")

    result = described_class.call(input: { email: " USER@example.com ", password: "Password123!" })

    expect(result.value!).to include(user: user_identity.user, user_identity:)
  end

  it "fails with invalid credentials when password does not match" do
    create(:user_identity, email: "user@example.com")

    result = described_class.call(input: { email: "user@example.com", password: "wrong-password" })

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:invalid_credentials)
  end

  it "fails when the account is suspended" do
    user = create(:user, status: "suspended")
    create(:user_identity, user:, email: "user@example.com")

    result = described_class.call(input: { email: "user@example.com", password: "Password123!" })

    expect(result).to be_failure
    expect(result.failure[:code]).to eq(:account_suspended)
  end
end
