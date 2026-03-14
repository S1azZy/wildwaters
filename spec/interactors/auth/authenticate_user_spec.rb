require "rails_helper"

RSpec.describe Auth::AuthenticateUser, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) { { email:, password: } }
  let(:email) { " USER@example.com " }
  let(:password) { "Password123!" }
  let!(:user_identity) { create(:user_identity, email: "user@example.com") }

  it "authenticates a password identity by normalized email" do
    expect(result).to be_success
    expect(result.value!).to include(user: user_identity.user, user_identity:)
  end

  context "when the password is invalid" do
    let(:password) { "wrong-password" }

    it "fails with invalid credentials" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:invalid_credentials)
    end
  end

  context "when the account is suspended" do
    let(:email) { "user@example.com" }
    let(:suspended_user) { create(:user, status: "suspended") }
    let!(:user_identity) { create(:user_identity, user: suspended_user, email: "user@example.com") }

    it "fails with an account suspended code" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:account_suspended)
    end
  end
end
