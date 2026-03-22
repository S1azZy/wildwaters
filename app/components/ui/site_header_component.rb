module Ui
  class SiteHeaderComponent < ApplicationComponent
    attr_reader :labels,
                :current_path,
                :authenticated,
                :explore_path,
                :dashboard_path,
                :map_path,
                :activity_path,
                :profile_path,
                :sign_in_path,
                :registration_path

    def initialize(
      labels:,
      current_path:,
      authenticated:,
      explore_path:,
      dashboard_path:,
      map_path: nil,
      activity_path: nil,
      profile_path:,
      sign_in_path:,
      registration_path:
    )
      @labels = labels.symbolize_keys
      @current_path = current_path
      @authenticated = authenticated
      @explore_path = explore_path
      @dashboard_path = dashboard_path
      @map_path = map_path
      @activity_path = activity_path
      @profile_path = profile_path
      @sign_in_path = sign_in_path
      @registration_path = registration_path
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
        navigation_item(:map, labels.fetch(:map), map_path),
        navigation_item(:activity, labels.fetch(:activity), activity_path),
        navigation_item(:profile, labels.fetch(:profile), profile_path)
      ]
    end

    def utility_actions
      return guest_actions unless authenticated

      [
        action_item(:notifications, labels.fetch(:notifications), nil, kind: :icon_button),
        action_item(:settings, labels.fetch(:settings), nil, kind: :icon_button),
        action_item(:profile, labels.fetch(:profile), dashboard_path, kind: :avatar_link)
      ]
    end

    private

    def guest_actions
      [
        action_item(:sign_in, labels.fetch(:sign_in), sign_in_path, kind: :button),
        action_item(:create_account, labels.fetch(:create_account), registration_path, kind: :button)
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

    def action_item(key, label, path, kind:)
      {
        key:,
        label:,
        path:,
        kind:
      }
    end

    def current?(key, path)
      return false if path.blank?

      return normalized_path(current_path) == normalized_path(path) if key == :explore

      normalized_path(current_path) == normalized_path(path)
    end

    def normalized_path(path)
      path.to_s.split(/[?#]/).first.presence || "/"
    end
  end
end
