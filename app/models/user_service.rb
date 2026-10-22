class UserService < ApplicationRecord
  belongs_to :user
  belongs_to :service

  validates :service_id, uniqueness: { scope: :user_id }
  validates :price,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validate :user_and_service_must_belong_to_same_account

  private

  def user_and_service_must_belong_to_same_account
    return if user.blank? || service.blank?
    return if user.account_id == service.account_id

    errors.add(:service, 'must belong to the same account as the user')
  end
end
