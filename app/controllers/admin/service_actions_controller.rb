module Admin
  class ServiceActionsController < BaseController
    layout "inertia", only: :index

    def index
      render inertia: "Admin/ServiceActions/Index", props: service_actions_props
    end

    def create_geonames_region_import
      result = Imports::GeoNames::EnqueueRegionImport.call

      if result.success?
        redirect_to admin_service_actions_path, notice: t("admin.service_actions.import_regions.flash.enqueued")
      else
        redirect_to admin_service_actions_path, alert: import_failure_message(result.failure.fetch(:code))
      end
    end

    private

    def service_actions_props
      {
        copy: {
          title: t("admin.service_actions.index.title"),
          heading: t("admin.service_actions.index.heading"),
          description: t("admin.service_actions.index.description"),
          toolbarLabel: t("admin.shell.toolbar_label"),
          importRegions: import_regions_copy
        },
        navigation: admin_navigation(current: "service_actions"),
        urls: {
          serviceActions: admin_service_actions_path,
          geonamesRegionImport: admin_service_actions_geonames_region_import_path
        },
        geonamesImport: {
          latestRun: latest_geonames_run_props
        }
      }
    end

    def import_regions_copy
      {
        title: t("admin.service_actions.import_regions.title"),
        description: t("admin.service_actions.import_regions.description"),
        button: t("admin.service_actions.import_regions.button"),
        emptyTitle: t("admin.service_actions.import_regions.empty_title"),
        emptyDescription: t("admin.service_actions.import_regions.empty_description"),
        latestRunTitle: t("admin.service_actions.import_regions.latest_run_title"),
        settingsTitle: t("admin.service_actions.import_regions.settings_title"),
        resultsTitle: t("admin.service_actions.import_regions.results_title"),
        failureTitle: t("admin.service_actions.import_regions.failure_title"),
        fields: {
          status: t("admin.service_actions.import_regions.fields.status"),
          mode: t("admin.service_actions.import_regions.fields.mode"),
          initiatedBy: t("admin.service_actions.import_regions.fields.initiated_by"),
          startedAt: t("admin.service_actions.import_regions.fields.started_at"),
          finishedAt: t("admin.service_actions.import_regions.fields.finished_at"),
          countries: t("admin.service_actions.import_regions.fields.countries"),
          languages: t("admin.service_actions.import_regions.fields.languages"),
          featureCodes: t("admin.service_actions.import_regions.fields.feature_codes"),
          itemCounts: t("admin.service_actions.import_regions.fields.item_counts")
        },
        statusLabels: Imports::Run::STATUSES.to_h do |_key, status|
          [ status.camelize(:lower), t("admin.service_actions.import_regions.statuses.#{status}") ]
        end
      }
    end

    def latest_geonames_run_props
      source = Imports::Source.find_by(key: ApplicationConfig.config.imports.geonames.source_key)
      return nil unless source

      run = source.runs.includes(:items).order(created_at: :desc, id: :desc).first
      return nil unless run

      {
        id: run.id,
        status: run.status,
        mode: run.mode,
        initiatedBy: run.initiated_by,
        startedAt: run.started_at&.iso8601,
        finishedAt: run.finished_at&.iso8601,
        settings: settings_props(run.params || {}),
        stats: stats_props(run.stats || {}),
        itemCounts: item_counts_props(run),
        failure: failure_props(run)
      }
    end

    def settings_props(params)
      {
        countries: params.fetch("countries", []),
        languages: params.fetch("languages", []),
        featureCodes: params.fetch("feature_codes", []),
        downloadAlternateNames: params["download_alternate_names"],
        downloadDir: params["download_dir"]
      }
    end

    def stats_props(stats)
      stats.to_h.transform_keys { |key| key.to_s.camelize(:lower) }
    end

    def item_counts_props(run)
      run.items.group(:status).count
    end

    def failure_props(run)
      item_messages = run.items
        .select { |item| item.error_message.present? }
        .map { |item| "#{item.item_key}: #{item.error_message}" }

      return nil if run.error_message.blank? && item_messages.empty?

      {
        className: run.error_class,
        message: run.error_message,
        itemMessages: item_messages
      }
    end

    def import_failure_message(code)
      t(
        "admin.service_actions.import_regions.flash.#{code}",
        default: t("admin.service_actions.import_regions.flash.failed")
      )
    end
  end
end
