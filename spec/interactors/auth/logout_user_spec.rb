require "rails_helper"

RSpec.describe Auth::LogoutUser, type: :interactor do
  it "revokes the session" do
    session_record = create(:session)

    freeze_time do
      result = described_class.call(input: { session: session_record })

      expect(result).to be_success
      expect(session_record.reload.revoked_at).to eq(Time.current)
    end
  end
end
