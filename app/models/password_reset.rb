class PasswordReset < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end

  def used?
    used_at.present?
  end

  def usable?
    !expired? && !used?
  end
end
