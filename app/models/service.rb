class Service < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true

  has_many :appointment_services, dependent: :destroy
  has_many :appointments, through: :appointment_services

  validates :title, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  scope :alphabetical, lambda { order(:title) }
end
