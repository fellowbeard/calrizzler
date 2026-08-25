class User < ApplicationRecord
  has_secure_password
  validates :email, uniqueness: true, presence: true
  belongs_to :account
  has_many :services, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :appointments, dependent: :nullify
  has_many :user_invitations, foreign_key: :invited_by_id, inverse_of: :invited_by, dependent: :destroy
  has_many :password_resets, dependent: :destroy

  ROLES = ['owner', 'staff', 'read_only'].freeze

  validates :role, inclusion: { in: ROLES }

  def owner?
    role == 'owner'
  end

  def staff?
    role == 'staff'
  end

  def read_only?
    role == 'read_only'
  end

  def can_write?
    owner? || staff?
  end
end
