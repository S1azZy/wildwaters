# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::UpdateUser, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      user_id: user.id,
      attributes:
    }
  end
  let(:user) do
    create(
      :user,
      display_name: "Old Name",
      primary_email: "member@example.com",
      locale: "en",
      role: "member",
      status: "active"
    )
  end
  let(:identity) { create(:user_identity, user:, email: user.primary_email) }
  let(:attributes) do
    {
      display_name: "  New Name  ",
      role: "admin",
      status: "suspended",
      primary_email: "changed@example.com",
      locale: "ru",
      password: "NewPassword123!",
      password_digest: "plaintext"
    }
  end

  before do
    identity
  end

  describe "ValidationContract" do
    subject(:validation) { described_class::ValidationContract.new.call(contract_input) }

    let(:contract_user_id) { SecureRandom.uuid }
    let(:contract_input) do
      {
        user_id: contract_user_id,
        attributes: {
          display_name: "Contract Name",
          role: "admin",
          status: "active",
          primary_email: "changed@example.com",
          locale: "ru",
          password: "NewPassword123!"
        }
      }
    end

    it "keeps only explicitly editable attributes" do
      expect(validation).to be_success
      expect(validation.to_h).to eq(
        user_id: contract_user_id,
        attributes: {
          display_name: "Contract Name",
          role: "admin",
          status: "active"
        }
      )
    end

    context "when role or status is outside the user domain" do
      let(:contract_input) do
        {
          user_id: contract_user_id,
          attributes: {
            role: "owner",
            status: "deleted"
          }
        }
      end

      it "returns validation errors for those attributes" do
        expect(validation).to be_failure
        expect(validation.errors.to_h).to include(
          attributes: include(
            role: be_present,
            status: be_present
          )
        )
      end
    end
  end

  it "returns success with the updated user" do
    expect(result).to be_success
    expect(result.value!).to include(user:)
  end

  it "updates only display name, role, and status" do
    old_password_digest = identity.password_digest

    result

    expect(user.reload).to have_attributes(
      display_name: "New Name",
      role: "admin",
      status: "suspended",
      primary_email: "member@example.com",
      locale: "en"
    )
    expect(identity.reload.password_digest).to eq(old_password_digest)
  end

  context "with a status-only update" do
    let(:attributes) { { status: "suspended" } }

    it "updates the status without changing other account fields" do
      result

      expect(user.reload).to have_attributes(
        display_name: "Old Name",
        role: "member",
        status: "suspended",
        primary_email: "member@example.com",
        locale: "en"
      )
    end
  end

  context "when the role or status is invalid" do
    let(:attributes) { { display_name: "Changed", role: "owner", status: "deleted" } }

    it "returns validation failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:validation_error)
      expect(result.failure[:errors]).to include(
        attributes: include(
          role: be_present,
          status: be_present
        )
      )
    end

    it "does not persist the invalid attributes" do
      expect { result }.not_to change { user.reload.attributes.slice("display_name", "role", "status") }
    end
  end

  context "when the user does not exist" do
    let(:input) { super().merge(user_id: SecureRandom.uuid) }

    it "returns user_not_found failure" do
      expect(result).to be_failure
      expect(result.failure).to eq(
        code: :user_not_found,
        errors: { user_id: [ "not found" ] }
      )
    end
  end
end
