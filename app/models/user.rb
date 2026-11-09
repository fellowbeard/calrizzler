class User < ApplicationRecord
  has_secure_password

  ROLES = ['owner', 'staff', 'read_only'].freeze

  belongs_to :account

  has_one_attached :avatar

  has_many :notes, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :appointments, dependent: :restrict_with_error
  has_many :user_working_hours, dependent: :destroy
  has_many :availability_blocks, dependent: :destroy
  has_many :user_invitations, foreign_key: :invited_by_id, inverse_of: :invited_by, dependent: :destroy
  has_many :password_resets, dependent: :destroy
  has_many :user_services, dependent: :destroy
  has_many :services, through: :user_services

  validates :email, uniqueness: true, presence: true
  validates :role, inclusion: { in: ROLES }

  validate :avatar_must_be_valid

  scope :active, lambda { where(active: true) }

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

  validate :avatar_must_be_valid

  private

  def avatar_must_be_valid
    return unless avatar.attached?

    allowed_types = ['image/jpeg', 'image/png', 'image/webp']

    errors.add(:avatar, 'must be a JPEG, PNG, or WebP image') unless allowed_types.include?(avatar.blob.content_type)

    return unless avatar.blob.byte_size > 5.megabytes

    errors.add(:avatar, 'must be smaller than 5 MB')
  end
end
