class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :resources, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :notes, through: :clients

  validates :business_name, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone::MAPPING.values }
end
