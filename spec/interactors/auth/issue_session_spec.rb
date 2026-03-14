require "rails_helper"

RSpec.describe Auth::IssueSession, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      user: user_identity.user,
      user_identity:,
      ip_address: "127.0.0.1",
      user_agent: "RSpec"
    }
  end
  let(:user_identity) { create(:user_identity) }

  around { |example| freeze_time(&example) }

  describe "#call" do
    it "creates a persisted session" do
      expect { result }.to change(Session, :count).by(1)
      expect(result).to be_success
    end

    it "returns a raw token that matches the stored digest" do
      expect { result }.to change(Session, :count).by(1)
      expect(result.value![:session].token_digest).to eq(Session.digest_token(result.value![:token]))
    end

    it "persists the expected attributes" do
      expect { result }.to change(Session, :count).by(1)
      expect(result.value![:session]).to have_attributes(
        user: user_identity.user,
        user_identity:,
        authentication_method: Auth::Constants::PASSWORD,
        ip_address: IPAddr.new("127.0.0.1"),
        user_agent: "RSpec",
        last_seen_at: Time.current,
        expires_at: 30.days.from_now
      )
    end
  end
end
