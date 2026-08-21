class Appointment < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :client
  belongs_to :resource

  has_many :appointment_services, dependent: :destroy
  has_many :services, through: :appointment_services

  STATUS_OPTIONS = ['scheduled', 'completed', 'canceled'].freeze

  validates :scheduled_at, presence: true
  # frontend defaults to status: "scheduled" when new apt is created
  validates :status, presence: true, inclusion: { in: STATUS_OPTIONS }
  validates :duration_minutes,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
            }

  validate :must_have_at_least_one_service
  validate :scheduled_at_cannot_be_in_the_past
  validate :resource_is_available

  def convert_time
    scheduled_at.strftime('%A, %B %d, %Y')
  end

  def service_duration_minutes
    services.sum(:duration_minutes)
  end

  def blocking_reservation_time
    duration_minutes
  end

  def ends_at
    scheduled_at + duration_minutes.minutes
  end

  def scheduled?
    status == 'scheduled'
  end

  def completed?
    status == 'completed'
  end

  def canceled?
    status == 'canceled'
  end

  def uses_default_duration?
    false
  end

  private

  def must_have_at_least_one_service
    return if services.to_a.any?

    errors.add(:services, :blank, message: 'must include at least one')
  end

  def scheduled_at_cannot_be_in_the_past
    return if scheduled_at.blank?
    return if completed? || canceled?
    return if scheduled_at >= Time.current

    errors.add(:scheduled_at, :past, message: 'cannot be scheduled in the past')
  end

  def resource_is_available
    return unless should_check_resource_availability?
    return unless overlapping_appointment?

    errors.add(:resource, :taken, message: 'is already booked at the scheduled time')
  end

  def should_check_resource_availability?
    resource_id.present? && scheduled_at.present? && !canceled?
  end

  def overlapping_appointment?
    possible_overlapping_appointments.any? do |appointment|
      overlaps_with?(appointment)
    end
  end

  def possible_overlapping_appointments
    account.appointments
           .where(resource_id: resource_id)
           .where.not(id: id)
           .where.not(status: 'canceled')
  end

  def overlaps_with?(appointment)
    scheduled_at < appointment.ends_at &&
      ends_at > appointment.scheduled_at
  end
end
