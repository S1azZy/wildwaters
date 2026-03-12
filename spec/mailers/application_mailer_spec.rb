# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationMailer do
  it "uses the default from address" do
    expect(described_class.default[:from]).to eq("from@example.com")
  end

  it "uses the mailer layout" do
    expect(described_class._layout).to eq("mailer")
  end
end
