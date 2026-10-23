class WorkingHour < ApplicationRecord
  belongs_to :account

  validates :day_of_week,
            presence: true,
            inclusion: { in: 0..6 }

  validates :opens_at, :closes_at, presence: true

  validate :closes_after_opens

  validate :hours_do_not_overlap

  private

  def closes_after_opens
    return if opens_at.blank? || closes_at.blank?
    return if closes_at > opens_at

    errors.add(:closes_at, 'must be after opening time')
  end

  def hours_do_not_overlap
    return unless account && day_of_week && opens_at && closes_at
    return unless overlapping_hours_exist?

    errors.add(:base, 'Working hours cannot overlap')
  end

  def overlapping_hours_exist?
    account.working_hours
           .where(day_of_week: day_of_week)
           .where.not(id: id)
           .where('opens_at < ? AND closes_at > ?', closes_at, opens_at)
           .exists?
  end
end
