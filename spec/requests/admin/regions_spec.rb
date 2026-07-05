# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin regions", type: :request do
  def sign_in_as(user_identity)
    post session_path, params: {
      session: {
        email: user_identity.email,
        password: "Password123!"
      }
    }
  end

  describe "GET /admin/regions" do
    it "redirects guests to sign in" do
      get "/admin/regions"

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("auth.sessions.require_authentication"))
    end

    it "redirects members to the explore homepage" do
      sign_in_as(create(:user_identity))

      get "/admin/regions"

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("admin.authorization.required"))
    end

    it "renders a least-data paginated regions directory for admins" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      hierarchy = create_region_hierarchy
      create_list(:region, 23, name: "Zed Region")
      sign_in_as(admin_identity)

      get "/admin/regions"

      expect_regions_index_contract
      expect(inertia.props.fetch("regions").size).to eq(25)
      expect(inertia.props.dig("pagination", "currentPage")).to eq(1)
      expect(inertia.props.dig("pagination", "nextUrl")).to eq("/admin/regions?page=2")
      expect_region_hierarchy_rows(hierarchy)
      expect_no_admin_regions_sensitive_props
    end

    it "filters regions by name, slug, or country code" do
      admin_identity = create(:user_identity, user: create(:user, role: "admin"), email: "admin@example.com")
      bali = create_region(name: "Bali", slug: "bali", region_kind: "area", country_code: "ID")
      lombok = create_region(name: "Lombok", slug: "lombok-island", region_kind: "area", country_code: "ID")
      create_region(name: "Quebec", slug: "quebec", region_kind: "area", country_code: "CA")
      sign_in_as(admin_identity)

      get "/admin/regions", params: { q: "ID" }

      expect(response).to have_http_status(:ok)
      expect(inertia.props.fetch("regions").pluck("id")).to contain_exactly(bali.id, lombok.id)
      expect(inertia.props.dig("query", "q")).to eq("ID")
    end
  end

  def create_region(**input)
    result = Regions::CreateRegion.call(input:)
    result.value![:region]
  end

  def create_region_hierarchy
    indonesia = create_region(name: "Indonesia", slug: "indonesia", region_kind: "country", country_code: "ID")
    bali = create_region(name: "Bali", slug: "bali", region_kind: "area", parent_id: indonesia.id, country_code: "ID")
    ubud = create_region(name: "Ubud", slug: "ubud", region_kind: "locality", parent_id: bali.id, country_code: "ID")

    { indonesia:, bali:, ubud: }
  end

  def expect_regions_index_contract
    expect(response).to have_http_status(:ok)
    expect(inertia).to be_inertia_response
    expect(inertia).to render_component("Admin/Regions/Index")
    expect(inertia.props.keys).to contain_exactly("copy", "errors", "navigation", "pagination", "query", "shell", "urls", "regions")
  end

  def admin_regions_sensitive_prop_keys
    %w[
      ancestor
      ancestorId
      ancestor_id
      center
      closure
      closures
      descendant
      descendantId
      descendant_id
      geometry
      import
      importSourceRecord
      import_source_record
      policy
      sourceLink
      source_links
    ]
  end

  def expect_no_admin_regions_sensitive_props
    expect(nested_keys(inertia.props)).not_to include(*admin_regions_sensitive_prop_keys)
  end

  def expect_region_hierarchy_rows(hierarchy)
    expect(region_row(hierarchy.fetch(:indonesia))).to include(
      region_props(hierarchy.fetch(:indonesia), depth: 0, parent_path: nil, children_count: 1)
    )
    expect(region_row(hierarchy.fetch(:bali))).to include(
      region_props(hierarchy.fetch(:bali), depth: 1, parent_path: "Indonesia", children_count: 1)
    )
    expect(region_row(hierarchy.fetch(:ubud))).to include(
      region_props(hierarchy.fetch(:ubud), depth: 2, parent_path: "Indonesia / Bali", children_count: 0)
    )
  end

  def region_row(region)
    inertia.props.fetch("regions").find { |row| row.fetch("id") == region.id }
  end

  def region_props(region, depth:, parent_path:, children_count:)
    {
      "childrenCount" => children_count,
      "countryCode" => region.country_code,
      "depth" => depth,
      "id" => region.id,
      "name" => region.name,
      "parentPath" => parent_path,
      "regionKind" => region.region_kind,
      "slug" => region.slug,
      "status" => region.status
    }
  end

  def nested_keys(value)
    case value
    when Hash
      value.flat_map { |key, nested_value| [ key, *nested_keys(nested_value) ] }
    when Array
      value.flat_map { |item| nested_keys(item) }
    else
      []
    end
  end
end
