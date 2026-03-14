require "rails_helper"

RSpec.describe Auth::ResetPassword, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      token:,
      password: "NewPassword123!",
      password_confirmation:
    }
  end
  let(:password_confirmation) { "NewPassword123!" }

  around { |example| freeze_time(&example) }

  describe "#call" do
    let(:stored_token) { "reset-token" }
    let(:token) { stored_token }
    let(:user_identity) do
      create(
        :user_identity,
        password_reset_token_digest: UserIdentity.digest_token(stored_token),
        password_reset_sent_at: 5.minutes.ago
      )
    end

    before do
      create(:session, user: user_identity.user, user_identity:)
      create(:session, user: user_identity.user, user_identity:)
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "updates the password" do
      result

      expect(user_identity.reload.authenticate("NewPassword123!")).to be(user_identity)
    end

    it "clears the password reset token fields" do
      expect { result }.to change { user_identity.reload.password_reset_token_digest }.to(nil)
        .and change { user_identity.reload.password_reset_sent_at }.to(nil)
    end

    it "revokes active sessions" do
      expect { result }.to change { Session.active.where(user: user_identity.user).count }.from(2).to(0)
    end

    context "when the token is invalid" do
      let(:token) { "missing-token" }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:invalid_token)
      end

      it "does not revoke active sessions" do
        expect { result }.not_to change { Session.active.where(user: user_identity.user).count }
      end
    end

    context "when the token is expired" do
      before do
        user_identity.update!(password_reset_sent_at: 31.minutes.ago)
      end

      it "returns failure" do
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:invalid_token)
      end
    end

    context "when the password is invalid" do
      let(:password_confirmation) { "Mismatch123!" }

      it "returns failure" do
        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:validation_error)
      end

      it "does not revoke active sessions" do
        expect { result }.not_to change { Session.active.where(user: user_identity.user).count }
      end
    end
  end
end
