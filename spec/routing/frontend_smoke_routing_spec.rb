# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Frontend smoke routing", type: :routing do
  it "routes the smoke page in the test environment" do
    expect(get: "/frontend/smoke").to route_to(
      controller: "frontend/smokes",
      action: "show",
    )
  end

  it "declares the route only for development and test environments" do
    routes = Rails.root.join("config/routes.rb").read

    expect(routes).to include("if Rails.env.development? || Rails.env.test?")
    expect(routes).to include("resource :smoke, only: :show")
  end
end
