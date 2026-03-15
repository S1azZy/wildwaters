require "rails_helper"

RSpec.describe AuthMailer do
  subject(:mail) { described_class.password_reset(user_identity:, token:) }

  let(:user_identity) { create(:user_identity, email: "identity@example.com") }
  let(:token) { "reset-token" }

  it "renders the subject" do
    expect(mail.subject).to eq(I18n.t("auth.password_resets.mailer.subject"))
  end

  it "sends to the user's primary email" do
    expect(mail.to).to eq([ user_identity.user.primary_email ])
  end

  it "includes the reset link" do
    expect(mail.body.encoded).to include(edit_password_reset_token_url(token))
  end
end
