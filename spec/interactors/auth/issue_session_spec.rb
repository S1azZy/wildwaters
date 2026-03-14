require "rails_helper"

RSpec.describe Auth::IssueSession, type: :interactor do
  let(:user_identity) { create(:user_identity) }

  around { |example| freeze_time(&example) }

  it "returns a raw token that matches the stored digest" do
    payload = issue_session_for(user_identity).value!
    expect(payload).to include(token: be_present)
    expect(payload[:session].token_digest).to eq(Session.digest_token(payload[:token]))
  end

  it "creates a persisted session with the expected attributes" do
    expect(issued_session_for(user_identity)).to have_attributes(
      user: user_identity.user,
      user_identity:,
      authentication_method: Auth::Constants::PASSWORD,
      ip_address: IPAddr.new("127.0.0.1"),
      user_agent: "RSpec",
      last_seen_at: Time.current,
      expires_at: 30.days.from_now
    )
  end

  def issued_session_for(user_identity)
    issue_session_for(user_identity).value![:session]
  end

  def issue_session_for(user_identity)
    described_class.call(input: {
      user: user_identity.user,
      user_identity:,
      ip_address: "127.0.0.1",
      user_agent: "RSpec"
    })
  end
end
