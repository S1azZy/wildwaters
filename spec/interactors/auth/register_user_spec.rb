require "rails_helper"

RSpec.describe Auth::RegisterUser, type: :interactor do
  it "creates a user and password identity" do
    result = register_user(email: " USER@example.com ", password_confirmation: "Password123!", locale: "ru")

    expect(result.value!).to include(
      user: have_attributes(primary_email: "user@example.com", locale: "ru"),
      user_identity: have_attributes(provider: Auth::Constants::PASSWORD)
    )
    expect([ User.count, UserIdentity.count ]).to eq([ 1, 1 ])
  end

  it "rolls back the user when password identity validation fails" do
    result = register_user(password_confirmation: "Mismatch123!")

    expect(result.failure[:code]).to eq(:validation_error)
    expect([ User.count, UserIdentity.count ]).to eq([ 0, 0 ])
  end

  def register_user(email: "user@example.com", password_confirmation:, locale: "en")
    described_class.call(input: {
      email:,
      password: "Password123!",
      password_confirmation:,
      locale:
    })
  end
end
