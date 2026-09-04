class Client < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :user

  has_many :appointments, dependent: :destroy
  has_many :appointment_services, through: :appointments
  has_many :services, through: :appointment_services
  has_many :notes, dependent: :destroy

  validates :first_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: /\A[\d\s\-+()]+\z/ }, allow_blank: true

  scope :for_user, lambda { |user|
    where(user_id: user.id)
  }

  before_validation :format_client

  private

  def format_client
    self.first_name = TextFormatter.titleize(first_name)
    self.last_name = TextFormatter.titleize(last_name)
    self.phone = TextFormatter.phone_number(phone)
    self.email = TextFormatter.email(email)
  end
end
