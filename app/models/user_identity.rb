class UserIdentity < ApplicationRecord
  belongs_to :user
  has_many :sessions, dependent: :destroy

  has_secure_password validations: false

  normalizes :email, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :provider, with: ->(value) { value.to_s.strip.downcase.presence }

  validates :provider, presence: true, inclusion: { in: Auth::Constants::PROVIDERS }
  validates :password, confirmation: true, if: :password_provider_with_password?
  validates :password_confirmation, presence: true, if: :password_provider_with_password?
  validates :provider_uid, uniqueness: { scope: :provider }, allow_nil: true
  validate :password_identity_requires_password_digest
  validate :external_identity_requires_provider_uid

  scope :password, -> { where(provider: Auth::Constants::PASSWORD) }

  private

  def password_identity_requires_password_digest
    return unless provider == Auth::Constants::PASSWORD
    return if password_digest.present?

    errors.add(:password_digest, :blank)
  end

  def external_identity_requires_provider_uid
    return if provider.blank? || provider == Auth::Constants::PASSWORD
    return if provider_uid.present?

    errors.add(:provider_uid, :blank)
  end

  def password_provider_with_password?
    provider == Auth::Constants::PASSWORD && password.present?
  end
end
