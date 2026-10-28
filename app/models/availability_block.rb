class AvailabilityBlock < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :account

  validates :starts_at, :ends_at, presence: true
  validate :ends_after_starts
  validate :valid_block_ownership
  validate :business_closures_cannot_be_available

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, 'must be after start time')
  end

  def valid_block_ownership
    if user.nil? && account.nil?
      errors.add(:base, 'Block must belong to an account or provider')
    elsif user && account && user.account_id != account.id
      errors.add(:account, 'must match the provider account')
    end
  end

  def business_closures_cannot_be_available
    return unless user.nil? && is_available?

    errors.add(:is_available, 'cannot be true for business-wide closures')
  end
end
