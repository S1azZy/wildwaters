class User < ApplicationRecord
  ROLES = %w[member admin].freeze
  STATUSES = %w[active suspended].freeze

  has_many :user_identities, dependent: :destroy
  has_many :sessions, dependent: :destroy

  normalizes :primary_email, with: ->(value) { value.to_s.strip.downcase.presence }

  validates :primary_email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :locale, presence: true, inclusion: { in: I18n.available_locales.map(&:to_s) }
end
