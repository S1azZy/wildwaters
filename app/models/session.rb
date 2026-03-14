class Session < ApplicationRecord
  belongs_to :user
  belongs_to :user_identity

  validates :authentication_method, presence: true, inclusion: { in: Auth::Constants::PROVIDERS }
  validates :last_seen_at, presence: true
  validates :expires_at, presence: true

  def active?
    !revoked? && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end
end
