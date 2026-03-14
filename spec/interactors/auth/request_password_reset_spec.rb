require "rails_helper"

RSpec.describe Auth::RequestPasswordReset, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) { { email: } }

  describe "#call" do
    let(:email) { user_identity.email }
    let!(:user_identity) { create(:user_identity, email: " user@example.com ") }

    around { |example| freeze_time(&example) }

    it "returns success" do
      expect(result).to be_success
    end

    it "stores a password reset digest and timestamp" do
      expect { result }.to change { user_identity.reload.password_reset_token_digest }.from(nil)
        .and change { user_identity.reload.password_reset_sent_at }.from(nil).to(Time.current)
    end

    it "delivers a password reset email" do
      expect { result }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it "delivers the email to the primary account address" do
      result

      expect(ActionMailer::Base.deliveries.last.to).to eq([ user_identity.user.primary_email ])
    end

    context "when the email does not exist" do
      let(:email) { "missing@example.com" }

      it "returns success" do
        expect(result).to be_success
      end

      it "does not deliver an email" do
        expect { result }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
