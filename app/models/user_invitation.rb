class UserInvitation < ApplicationRecord
  INVITABLE_ROLES = ['staff', 'read_only'].freeze

  belongs_to :account
  belongs_to :invited_by, class_name: 'User', inverse_of: :user_invitations

  validates :email, presence: true
  validates :role, inclusion: { in: INVITABLE_ROLES }
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :email_must_not_already_exist, on: :create
  validate :inviter_must_belong_to_same_account

  def expired?
    expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def usable?
    !expired? && !accepted?
  end

  private

  def email_must_not_already_exist
    return unless User.exists?(email: email)

    errors.add(:email, 'already belongs to an existing user')
  end

  def inviter_must_belong_to_same_account
    return if account.blank? || invited_by.blank?
    return if invited_by.account_id == account_id

    errors.add(:invited_by, 'must belong to the same account')
  end
end
