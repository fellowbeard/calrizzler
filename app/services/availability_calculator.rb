class AvailabilityCalculator
  SLOT_INTERVAL = 15.minutes

  def initialize(user:, date:, duration_minutes:, resource:)
    @user = user
    @account = user.account
    @date = date.to_date
    @duration = duration_minutes.to_i.minutes
    @resource = resource
    @timezone = Time.find_zone!(@account.timezone)

    raise ArgumentError, 'Duration must be positive' unless duration_minutes.to_i.positive?
    raise ArgumentError, 'Resource must belong to account' unless resource.account_id == @account.id
  end

  def available_slots
    intervals = recurring_intervals

    intervals = subtract_intervals(intervals, business_closures) if inherits_business_hours?

    intervals += provider_exceptions(true)
    intervals = merge_intervals(intervals)

    intervals = subtract_intervals(intervals, provider_exceptions(false))
    intervals = subtract_intervals(intervals, occupied_intervals)

    intervals.flat_map { |start_time, end_time| slots_between(start_time, end_time) }
             .uniq
             .sort
  end

  private

  def day_start
    @day_start ||= @timezone.local(@date.year, @date.month, @date.day)
  end

  def day_end
    @day_end ||= day_start.advance(days: 1)
  end

  def provider_hours
    @provider_hours ||= @user.user_working_hours.where(day_of_week: @date.wday).to_a
  end

  def inherits_business_hours?
    provider_hours.empty?
  end

  def recurring_intervals
    hours = if inherits_business_hours?
              @account.working_hours.where(day_of_week: @date.wday)
            else
              provider_hours.reject(&:is_closed?)
            end

    hours.map do |hour|
      [local_time(hour.opens_at), local_time(hour.closes_at)]
    end
  end

  def local_time(time)
    @timezone.local(
      @date.year, @date.month, @date.day,
      time.hour, time.min, time.sec
    )
  end

  def business_closures
    dated_intervals(@account.availability_blocks.where(user_id: nil, is_available: false))
  end

  def provider_exceptions(is_available)
    dated_intervals(@user.availability_blocks.where(is_available: is_available))
  end

  def dated_intervals(records)
    records.where('starts_at < ? AND ends_at > ?', day_end, day_start)
           .map { |record| [record.starts_at, record.ends_at] }
  end

  def occupied_intervals
    appointments = @account.appointments
                           .where.not(status: 'canceled')
                           .where('scheduled_at < ?', day_end)
                           .where(
                             'user_id = :user_id OR resource_id = :resource_id',
                             user_id: @user.id,
                             resource_id: @resource.id
                           )

    appointments.filter_map do |appointment|
      next unless appointment.ends_at > day_start

      [appointment.scheduled_at, appointment.ends_at]
    end
  end

  def subtract_intervals(intervals, exclusions)
    exclusions.reduce(intervals) do |remaining, (excluded_start, excluded_end)|
      remaining.flat_map do |start_time, end_time|
        if excluded_end <= start_time || excluded_start >= end_time
          [[start_time, end_time]]
        else
          [
            [start_time, [excluded_start, end_time].min],
            [[excluded_end, start_time].max, end_time],
          ].select { |first, last| first < last }
        end
      end
    end
  end

  def slots_between(start_time, end_time)
    start_time = [start_time, day_start, Time.current].max
    end_time = [end_time, day_end].min

    slots = []
    cursor = Time.zone.at((start_time.to_i.to_f / SLOT_INTERVAL).ceil * SLOT_INTERVAL)

    while cursor + @duration <= end_time
      slots << cursor.utc.iso8601
      cursor += SLOT_INTERVAL
    end

    slots
  end

  def merge_intervals(intervals)
    intervals.sort_by(&:first).each_with_object([]) do |(start_time, end_time), merged|
      if merged.any? && start_time <= merged.last[1]
        merged.last[1] = [merged.last[1], end_time].max
      else
        merged << [start_time, end_time]
      end
    end
  end
end
