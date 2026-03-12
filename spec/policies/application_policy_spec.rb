# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  before do
    stub_const("SpecPolicyUser", Class.new)
    stub_const("SpecPolicyRecord", Class.new)
    stub_const("SpecPolicyRelation", Class.new)
  end

  let(:user) { instance_double(SpecPolicyUser) }
  let(:record) { instance_double(SpecPolicyRecord) }

  it "denies all default actions" do
    expect([
      policy.index?,
      policy.show?,
      policy.create?,
      policy.new?,
      policy.update?,
      policy.edit?,
      policy.destroy?
    ]).to eq([ false, false, false, false, false, false, false ])
  end

  describe ApplicationPolicy::Scope do
    subject(:scope) { described_class.new(user, relation) }

    let(:user) { instance_double(SpecPolicyUser) }
    let(:relation) { instance_double(SpecPolicyRelation) }

    it "raises until a concrete scope implements resolve" do
      expect { scope.resolve }.to raise_error(
        NoMethodError,
        "You must define #resolve in ApplicationPolicy::Scope"
      )
    end
  end
end
