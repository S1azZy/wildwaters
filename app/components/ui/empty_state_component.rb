module Ui
  class EmptyStateComponent < ApplicationComponent
    renders_one :icon
    renders_one :action

    attr_reader :title, :body

    def initialize(title:, body:)
      @title = title
      @body = body
    end
  end
end
