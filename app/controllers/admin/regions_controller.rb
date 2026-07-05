module Admin
  class RegionsController < BaseController
    include Pagy::Method

    PAGE_SIZE = 25

    layout "inertia"

    def index
      pagy, regions = pagy(:offset, regions_scope, limit: PAGE_SIZE)

      render inertia: "Admin/Regions/Index", props: index_props(pagy:, regions:)
    end

    private

    def regions_scope
      scope = Region.order(:name, :id)
      return scope if search_query.blank?

      term = "%#{ActiveRecord::Base.sanitize_sql_like(search_query)}%"
      scope.where("name ILIKE :term OR slug ILIKE :term OR country_code ILIKE :term", term:)
    end

    def index_props(pagy:, regions:)
      hierarchy = hierarchy_context(regions)

      {
        copy: regions_index_copy(pagy:),
        navigation: admin_navigation(current: "regions"),
        pagination: pagination_props(pagy),
        query: {
          q: search_query
        },
        urls: {
          index: admin_regions_path
        },
        regions: regions.map { |region| region_row_props(region, hierarchy:) }
      }
    end

    def pagination_props(pagy)
      urls = pagy.urls_hash

      {
        currentPage: pagy.page,
        nextUrl: urls[:next],
        previousUrl: urls[:previous],
        totalCount: pagy.count,
        totalPages: pagy.last
      }
    end

    def region_row_props(region, hierarchy:)
      {
        id: region.id,
        name: region.name,
        slug: region.slug,
        regionKind: region.region_kind,
        status: region.status,
        countryCode: region.country_code,
        parentPath: hierarchy.fetch(:parent_paths).fetch(region.id, nil),
        depth: hierarchy.fetch(:depths).fetch(region.id, 0),
        childrenCount: hierarchy.fetch(:children_counts).fetch(region.id, 0),
        createdAt: format_admin_time(region.created_at)
      }
    end

    def hierarchy_context(regions)
      region_ids = regions.map(&:id)

      {
        depths: region_depths(region_ids),
        parent_paths: region_parent_paths(region_ids),
        children_counts: Region.where(parent_id: region_ids).group(:parent_id).count
      }
    end

    def region_depths(region_ids)
      RegionClosure.where(descendant_id: region_ids).group(:descendant_id).maximum(:depth)
    end

    def region_parent_paths(region_ids)
      closures = RegionClosure
        .where(descendant_id: region_ids)
        .where.not(depth: 0)
        .includes(:ancestor)
        .group_by(&:descendant_id)

      closures.transform_values do |ancestor_closures|
        ancestor_closures
          .sort_by { |closure| -closure.depth }
          .map { |closure| closure.ancestor.name }
          .join(" / ")
      end
    end

    def regions_index_copy(pagy:)
      {
        title: t("admin.regions.index.title"),
        heading: t("admin.regions.index.heading"),
        description: t("admin.regions.index.description"),
        toolbarLabel: t("admin.shell.toolbar_label"),
        searchLabel: t("admin.regions.index.search_label"),
        searchPlaceholder: t("admin.regions.index.search_placeholder"),
        searchSubmit: t("admin.regions.index.search_submit"),
        emptyCountryCode: t("admin.regions.index.empty_country_code"),
        emptyParentPath: t("admin.regions.index.empty_parent_path"),
        emptyTitle: t("admin.regions.index.empty_title"),
        emptyDescription: t("admin.regions.index.empty_description"),
        tableCaption: t("admin.regions.index.table_caption"),
        levelLabel: t("admin.regions.index.level_label"),
        childrenCount: {
          zero: t("admin.regions.index.children_count.zero"),
          one: t("admin.regions.index.children_count.one"),
          other: t("admin.regions.index.children_count.other")
        },
        columns: {
          region: t("admin.regions.index.columns.region"),
          kind: t("admin.regions.index.columns.kind"),
          status: t("admin.regions.index.columns.status"),
          countryCode: t("admin.regions.index.columns.country_code"),
          parentPath: t("admin.regions.index.columns.parent_path"),
          children: t("admin.regions.index.columns.children"),
          createdAt: t("admin.regions.index.columns.created_at")
        },
        pagination: {
          label: t("admin.regions.index.pagination.label"),
          previous: t("admin.regions.index.pagination.previous"),
          next: t("admin.regions.index.pagination.next"),
          summary: t(
            "admin.regions.index.pagination.summary",
            from: pagy.from,
            to: pagy.to,
            count: pagy.count
          )
        }
      }
    end

    def search_query
      @search_query ||= params[:q].to_s.squish
    end

    def format_admin_time(time)
      I18n.l(time.to_date, format: :long)
    end
  end
end
