module Ui
  class AuthFooterComponent < ApplicationComponent
    attr_reader :author, :note

    def initialize(author:, note:)
      @author = author
      @note = note
    end
  end
end
