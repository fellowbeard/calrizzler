class UserWorkingHour < ApplicationRecord
  belongs_to :user

  validates :day_of_week,
            presence: true,
            inclusion: { in: 0..6 }

  validates :opens_at, :closes_at, presence: true, unless: :is_closed?
  validate :closed_day_has_no_times
  validate :closed_day_does_not_conflict

  validate :closes_after_opens
  validate :hours_do_not_overlap

  private

  def closes_after_opens
    return if opens_at.blank? || closes_at.blank?
    return if closes_at > opens_at

    errors.add(:closes_at, 'must be after opening time')
  end

  def hours_do_not_overlap
    return unless user && !day_of_week.nil? && opens_at && closes_at
    return unless overlapping_hours_exist?

    errors.add(:base, 'Working hours cannot overlap')
  end

  def overlapping_hours_exist?
    user.user_working_hours
        .where(day_of_week: day_of_week)
        .where.not(id: id)
        .where('opens_at < ? AND closes_at > ?', closes_at, opens_at)
        .exists?
  end

  def closed_day_has_no_times
    return unless is_closed?
    return if opens_at.nil? && closes_at.nil?

    errors.add(:base, 'Closed days cannot have working hours')
  end

  def closed_day_does_not_conflict
    return unless user && !day_of_week.nil?

    other_hours = user.user_working_hours
                      .where(day_of_week: day_of_week)
                      .where.not(id: id)

    if is_closed?
      errors.add(:base, 'Cannot close a day with existing working hours') if other_hours.exists?
    elsif other_hours.where(is_closed: true).exists?
      errors.add(:base, 'Cannot add working hours to a closed day')
    end
  end
end
