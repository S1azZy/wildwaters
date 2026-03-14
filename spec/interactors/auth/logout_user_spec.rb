require "rails_helper"

RSpec.describe Auth::LogoutUser, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) { { session: session_record } }
  let(:session_record) { create(:session) }

  around { |example| freeze_time(&example) }

  it "returns success" do
    expect(result).to be_success
  end

  it "revokes the session" do
    expect { result }.to change { session_record.reload.revoked_at }.from(nil).to(Time.current)
  end
end
