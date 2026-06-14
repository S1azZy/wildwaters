# frozen_string_literal: true

module Frontend
  class SmokesController < ApplicationController
    layout "inertia"

    def show
      render inertia: "Frontend/Smoke", props: {
        copy: {
          action: I18n.t("frontend.smoke.action"),
          description: I18n.t("frontend.smoke.description"),
          eyebrow: I18n.t("frontend.smoke.eyebrow"),
          interaction: I18n.t("frontend.smoke.interaction"),
          title: I18n.t("frontend.smoke.title")
        },
        csrfToken: form_authenticity_token,
        urls: {
          home: root_path
        }
      }
    end
  end
end
