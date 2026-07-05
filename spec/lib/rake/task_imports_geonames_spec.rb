# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe Rake::Task do
  before do
    Rails.application.load_tasks
  end

  it "does not expose GeoNames import operator launch tasks" do
    expect(described_class.task_defined?("imports:geonames:enqueue")).to be(false)
    expect(described_class.task_defined?("imports:geonames:retry_failed")).to be(false)
    expect(described_class.task_defined?("imports:geonames:regions")).to be(false)
    expect(described_class.task_defined?("imports:geonames:regions_from_network")).to be(false)
  end
end
