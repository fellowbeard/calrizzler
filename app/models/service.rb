class Service < ApplicationRecord
  belongs_to :account

  has_many :user_services, dependent: :destroy
  has_many :users, through: :user_services
  has_many :appointment_services, dependent: :destroy
  has_many :appointments, through: :appointment_services

  validates :title, presence: true, uniqueness: { scope: :account_id }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  scope :alphabetical, lambda { order(:title) }
  scope :active, lambda { where(archived_at: nil) }
  scope :archived, lambda { where.not(archived_at: nil) }

  before_validation :format_text

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def restore!
    update!(archived_at: nil)
  end

  private

  def format_text
    self.title = TextFormatter.titleize(title)
    self.description = TextFormatter.capitalize_first(description)
  end
end
