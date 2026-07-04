# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin users", type: :request do
  def sign_in_as(user_identity)
    post session_path, params: {
      session: {
        email: user_identity.email,
        password: "Password123!"
      }
    }
  end

  describe "GET /admin/users" do
    it "redirects guests to sign in" do
      get "/admin/users"

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication"))
    end

    it "redirects members to the explore homepage" do
      sign_in_as(create(:user_identity))

      get "/admin/users"

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("admin.authorization.required"))
    end

    it "renders a least-data paginated users directory for admins" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      create_list(:user, 27)
      newest = create(:user, display_name: "Newest Person", primary_email: "newest@example.com", locale: "ru")
      create(:user_identity, user: newest, email: newest.primary_email)
      sign_in_as(admin_identity)

      get "/admin/users"

      expect_users_index_contract
      expect(inertia.props.dig("users", 0)).to include(user_props(newest))
      expect_no_admin_users_sensitive_props
    end

    it "filters users by email or display name" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      matching_by_name = create(:user, display_name: "River Guide", primary_email: "guide@example.com")
      matching_by_email = create(:user, display_name: "Unrelated", primary_email: "river@example.com")
      create(:user, display_name: "Forest Ranger", primary_email: "forest@example.com")
      sign_in_as(admin_identity)

      get "/admin/users", params: { q: "river" }

      expect(response).to have_http_status(:ok)
      expect(inertia.props.fetch("users").pluck("id")).to contain_exactly(matching_by_name.id, matching_by_email.id)
      expect(inertia.props.dig("query", "q")).to eq("river")
    end
  end

  describe "GET /admin/users/:id/edit" do
    it "renders editable account fields and read-only account details" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      user = create(:user, display_name: "Ayla Stone", primary_email: "ayla@example.com", locale: "ru")
      sign_in_as(admin_identity)

      get "/admin/users/#{user.id}/edit"

      expect_users_edit_contract
      expect(inertia.props.fetch("user")).to include(user_props(user))
      expect_no_admin_users_sensitive_props
    end
  end

  describe "PATCH /admin/users/:id" do
    it "updates only display name, role, and status" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      user = create(:user, display_name: "Old Name", primary_email: "member@example.com", locale: "en")
      identity = create(:user_identity, user:, email: user.primary_email)
      old_password_digest = identity.password_digest
      sign_in_as(admin_identity)

      patch "/admin/users/#{user.id}", params: disallowed_update_params

      expect_admin_users_redirect(:updated)
      expect(user.reload).to have_attributes(updated_allowed_user_attributes)
      expect(identity.reload.password_digest).to eq(old_password_digest)
    end

    it "re-renders validation feedback for invalid role or status" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      user = create(:user, display_name: "Stable Name", role: "member", status: "active")
      sign_in_as(admin_identity)

      patch "/admin/users/#{user.id}", params: {
        user: {
          display_name: "Changed",
          role: "owner",
          status: "deleted"
        }
      }

      expect_invalid_update_response
      expect(user.reload).to have_attributes(display_name: "Stable Name", role: "member", status: "active")
    end
  end

  describe "PATCH /admin/users/:id/status" do
    it "suspends an active user without changing other account fields" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      user = create(:user, display_name: "Member", role: "member", status: "active", primary_email: "member@example.com")
      identity = create(:user_identity, user:, email: user.primary_email)
      old_password_digest = identity.password_digest
      sign_in_as(admin_identity)

      patch "/admin/users/#{user.id}/status", params: { status: "suspended" }

      expect_admin_users_redirect(:suspended)
      expect(user.reload).to have_attributes(suspended_user_attributes)
      expect(identity.reload.password_digest).to eq(old_password_digest)
    end

    it "reactivates a suspended user" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      user = create(:user, status: "suspended")
      sign_in_as(admin_identity)

      patch "/admin/users/#{user.id}/status", params: { status: "active" }

      expect_admin_users_redirect(:reactivated)
      expect(user.reload.status).to eq("active")
    end
  end

  def admin_users_sensitive_prop_keys
    %w[
      credential
      credentials
      current_user
      identity
      identities
      password
      passwordDigest
      password_digest
      policy
      primary_email
      reset_token
      session
      sessions
      token
      userIdentity
      user_identity
    ]
  end

  def expect_users_index_contract
    expect(response).to have_http_status(:ok)
    expect(inertia).to be_inertia_response
    expect(inertia).to render_component("Admin/Users/Index")
    expect(inertia.props.keys).to contain_exactly("copy", "errors", "navigation", "pagination", "query", "shell", "urls", "users")
    expect(inertia.props.fetch("users").size).to eq(25)
    expect(inertia.props.dig("pagination", "currentPage")).to eq(1)
    expect(inertia.props.dig("pagination", "nextUrl")).to eq("/admin/users?page=2")
  end

  def expect_users_edit_contract
    expect(response).to have_http_status(:ok)
    expect(inertia).to be_inertia_response
    expect(inertia).to render_component("Admin/Users/Edit")
    expect(inertia.props.keys).to contain_exactly("copy", "errors", "navigation", "options", "shell", "urls", "user")
    expect(inertia.props.dig("options", "roles").pluck("value")).to contain_exactly("member", "admin")
    expect(inertia.props.dig("options", "statuses").pluck("value")).to contain_exactly("active", "suspended")
  end

  def expect_no_admin_users_sensitive_props
    expect(nested_keys(inertia.props)).not_to include(*admin_users_sensitive_prop_keys)
  end

  def expect_admin_users_redirect(flash_key)
    expect(response).to redirect_to("/admin/users")
    expect(flash[:notice]).to eq(I18n.t("admin.users.flash.#{flash_key}"))
  end

  def expect_invalid_update_response
    expect(response).to have_http_status(:unprocessable_content)
    expect(inertia).to render_component("Admin/Users/Edit")
  end

  def user_props(user)
    {
      "displayName" => user.display_name,
      "email" => user.primary_email,
      "locale" => user.locale,
      "role" => user.role,
      "status" => user.status
    }
  end

  def updated_allowed_user_attributes
    {
      display_name: "New Name",
      role: "admin",
      status: "suspended",
      primary_email: "member@example.com",
      locale: "en"
    }
  end

  def disallowed_update_params
    {
      user: {
        display_name: "  New Name  ",
        role: "admin",
        status: "suspended",
        primary_email: "changed@example.com",
        locale: "ru",
        password: "NewPassword123!",
        password_digest: "plaintext"
      }
    }
  end

  def suspended_user_attributes
    {
      display_name: "Member",
      role: "member",
      status: "suspended",
      primary_email: "member@example.com"
    }
  end
end
