class AppointmentService < ApplicationRecord
  belongs_to :appointment
  belongs_to :service

  validates :appointment_id, uniqueness: { scope: :service_id }
end
