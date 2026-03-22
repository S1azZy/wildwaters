module Ui
  class SiteHeaderComponent < ApplicationComponent
    attr_reader :labels,
                :current_path,
                :authenticated,
                :explore_path,
                :info_path,
                :dashboard_path,
                :sign_in_path,
                :registration_path,
                :session_path

    def initialize(
      labels:,
      current_path:,
      authenticated:,
      explore_path:,
      info_path:,
      dashboard_path:,
      sign_in_path:,
      registration_path:,
      session_path:
    )
      @labels = labels.symbolize_keys
      @current_path = current_path
      @authenticated = authenticated
      @explore_path = explore_path
      @info_path = info_path
      @dashboard_path = dashboard_path
      @sign_in_path = sign_in_path
      @registration_path = registration_path
      @session_path = session_path
    end

    def brand_name
      labels.fetch(:brand_name)
    end

    def brand_tagline
      labels.fetch(:brand_tagline)
    end

    def navigation_items
      [
        navigation_item(:explore, labels.fetch(:explore), explore_path),
        navigation_item(:info, labels.fetch(:info), info_path)
      ]
    end

    def session_actions
      return guest_actions unless authenticated

      [
        action_item(:dashboard, labels.fetch(:dashboard), dashboard_path),
        action_item(:sign_out, labels.fetch(:sign_out), session_path, method: :delete)
      ]
    end

    private

    def guest_actions
      [
        action_item(:sign_in, labels.fetch(:sign_in), sign_in_path),
        action_item(:create_account, labels.fetch(:create_account), registration_path)
      ]
    end

    def navigation_item(key, label, path)
      {
        key:,
        label:,
        path:,
        current: current?(key, path)
      }
    end

    def action_item(key, label, path, method: nil)
      {
        key:,
        label:,
        path:,
        method:
      }
    end

    def current?(key, path)
      return false if current_path.to_s.include?("#")
      return false unless key == :explore

      normalized_path(current_path) == normalized_path(path)
    end

    def normalized_path(path)
      path.to_s.split(/[?#]/).first.presence || "/"
    end
  end
end
