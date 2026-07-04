module Admin
  class UsersController < BaseController
    include Pagy::Method

    PAGE_SIZE = 25

    layout "inertia"

    def index
      pagy, users = pagy(:offset, users_scope, limit: PAGE_SIZE)

      render inertia: "Admin/Users/Index", props: index_props(pagy:, users:)
    end

    def edit
      render inertia: "Admin/Users/Edit", props: edit_props(user: admin_user)
    end

    def update
      result = update_admin_user(attributes: user_params)

      if result.success?
        redirect_to admin_users_path, notice: t("admin.users.flash.updated"), status: :see_other
      else
        render inertia: "Admin/Users/Edit", props: edit_props(user: admin_user), status: :unprocessable_content
      end
    end

    def status
      result = update_admin_user(attributes: { status: params.expect(:status) })
      return head :bad_request if result.failure?

      user = result.value![:user]
      redirect_to admin_users_path, notice: t("admin.users.flash.#{status_flash_key(user)}"), status: :see_other
    end

    private

    def users_scope
      scope = User.order(created_at: :desc, id: :desc)
      return scope if search_query.blank?

      term = "%#{ActiveRecord::Base.sanitize_sql_like(search_query)}%"
      scope.where("primary_email::text ILIKE :term OR display_name ILIKE :term", term:)
    end

    def index_props(pagy:, users:)
      {
        copy: users_index_copy(pagy:),
        navigation: admin_navigation(current: "users"),
        pagination: pagination_props(pagy),
        query: {
          q: search_query
        },
        urls: {
          index: admin_users_path
        },
        users: users.map { |user| user_row_props(user) }
      }
    end

    def edit_props(user:)
      {
        copy: users_edit_copy,
        navigation: admin_navigation(current: "users"),
        options: {
          roles: User::ROLES.map { |role| option_props("admin.users.roles.#{role}", role) },
          statuses: User::STATUSES.map { |status| option_props("admin.users.statuses.#{status}", status) }
        },
        urls: {
          index: admin_users_path,
          update: admin_user_path(user)
        },
        user: user_detail_props(user)
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

    def user_row_props(user)
      {
        id: user.id,
        displayName: user.display_name,
        email: user.primary_email,
        role: user.role,
        status: user.status,
        locale: user.locale,
        createdAt: format_admin_time(user.created_at),
        editUrl: edit_admin_user_path(user),
        statusUrl: status_admin_user_path(user),
        nextStatus: user.suspended? ? "active" : "suspended"
      }
    end

    def user_detail_props(user)
      user_row_props(user).slice(
        :id,
        :displayName,
        :email,
        :role,
        :status,
        :locale,
        :createdAt
      ).merge(updatedAt: format_admin_time(user.updated_at))
    end

    def users_index_copy(pagy:)
      {
        title: t("admin.users.index.title"),
        heading: t("admin.users.index.heading"),
        description: t("admin.users.index.description"),
        toolbarLabel: t("admin.shell.toolbar_label"),
        searchLabel: t("admin.users.index.search_label"),
        searchPlaceholder: t("admin.users.index.search_placeholder"),
        searchSubmit: t("admin.users.index.search_submit"),
        emptyDisplayName: t("admin.users.index.empty_display_name"),
        emptyTitle: t("admin.users.index.empty_title"),
        emptyDescription: t("admin.users.index.empty_description"),
        tableCaption: t("admin.users.index.table_caption"),
        columns: {
          displayName: t("admin.users.index.columns.display_name"),
          email: t("admin.users.index.columns.email"),
          role: t("admin.users.index.columns.role"),
          status: t("admin.users.index.columns.status"),
          locale: t("admin.users.index.columns.locale"),
          createdAt: t("admin.users.index.columns.created_at"),
          actions: t("admin.users.index.columns.actions")
        },
        actions: {
          edit: t("admin.users.actions.edit"),
          suspend: t("admin.users.actions.suspend"),
          reactivate: t("admin.users.actions.reactivate")
        },
        pagination: {
          label: t("admin.users.index.pagination.label"),
          previous: t("admin.users.index.pagination.previous"),
          next: t("admin.users.index.pagination.next"),
          summary: t(
            "admin.users.index.pagination.summary",
            from: pagy.from,
            to: pagy.to,
            count: pagy.count
          )
        }
      }
    end

    def users_edit_copy
      {
        title: t("admin.users.edit.title"),
        heading: t("admin.users.edit.heading"),
        description: t("admin.users.edit.description"),
        toolbarLabel: t("admin.shell.toolbar_label"),
        back: t("admin.users.edit.back"),
        detailsHeading: t("admin.users.edit.details_heading"),
        formHeading: t("admin.users.edit.form_heading"),
        submit: t("admin.users.edit.submit"),
        fields: {
          displayName: {
            label: t("admin.users.edit.fields.display_name.label"),
            placeholder: t("admin.users.edit.fields.display_name.placeholder")
          },
          role: {
            label: t("admin.users.edit.fields.role.label")
          },
          status: {
            label: t("admin.users.edit.fields.status.label")
          }
        },
        details: {
          email: t("admin.users.edit.details.email"),
          locale: t("admin.users.edit.details.locale"),
          createdAt: t("admin.users.edit.details.created_at"),
          updatedAt: t("admin.users.edit.details.updated_at")
        }
      }
    end

    def option_props(label_key, value)
      {
        label: t(label_key),
        value:
      }
    end

    def admin_user
      @admin_user ||= User.find(params[:id])
    end

    def user_params
      params.expect(user: %i[display_name role status]).to_h
    end

    def status_flash_key(user)
      user.suspended? ? "suspended" : "reactivated"
    end

    def update_admin_user(attributes:)
      Admin::UpdateUser.call(
        input: {
          user_id: params[:id],
          attributes:
        }
      )
    end

    def search_query
      @search_query ||= params[:q].to_s.squish
    end

    def format_admin_time(time)
      I18n.l(time.to_date, format: :long)
    end
  end
end
