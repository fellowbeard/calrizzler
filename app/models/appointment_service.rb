class AppointmentService < ApplicationRecord
  belongs_to :appointment
  belongs_to :service

  before_validation :capture_price_at_booking, on: :create

  validates :appointment_id, uniqueness: { scope: :service_id }

  validates :price_at_booking,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  private

  def capture_price_at_booking
    return if price_at_booking.present?
    return if appointment&.user.blank? || service.blank?

    offering = UserService.find_by(
      user: appointment.user,
      service: service
    )

    if offering
      self.price_at_booking = offering.price
    else
      errors.add(:service, 'is not offered by this provider')
    end
  end
end
