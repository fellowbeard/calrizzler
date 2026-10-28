require 'rails_helper'

RSpec.describe AvailabilityCalculator do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { create(:account, timezone: 'America/Chicago') }
  let(:user) { create(:user, account: account) }
  let(:resource) { create(:resource, account: account) }
  let(:date) { Date.new(2026, 11, 9) } # Monday
  let(:timezone) { Time.find_zone!(account.timezone) }

  def local_time(hour, minute = 0)
    timezone.local(date.year, date.month, date.day, hour, minute)
  end

  def business_hours(opens_at: '09:00', closes_at: '17:00')
    create(
      :working_hour,
      account: account,
      day_of_week: date.wday,
      opens_at: opens_at,
      closes_at: closes_at
    )
  end

  def provider_hours(opens_at: '09:00', closes_at: '17:00', is_closed: false)
    create(
      :user_working_hour,
      user: user,
      day_of_week: date.wday,
      opens_at: opens_at,
      closes_at: closes_at,
      is_closed: is_closed
    )
  end

  def availability_block(starts_at:, ends_at:, is_available:, user: nil)
    create(
      :availability_block,
      account: account,
      user: user,
      starts_at: starts_at,
      ends_at: ends_at,
      is_available: is_available
    )
  end

  def slots(duration: 60, selected_resource: resource)
    described_class.new(
      user: user,
      date: date,
      duration_minutes: duration,
      resource: selected_resource
    ).available_slots
  end

  def slot_at(hour, minute = 0)
    local_time(hour, minute).utc.iso8601
  end

  def booked_appointment(provider:, booked_resource:, starts_at:, duration: 60, status: 'scheduled')
    service = create(:service, account: account, duration_minutes: duration)

    create(:user_service, user: provider, service: service)

    appointment = provider.appointments.new(
      account: account,
      client: create(:client, account: account, user: provider),
      resource: booked_resource,
      scheduled_at: starts_at,
      duration_minutes: duration,
      status: status
    )

    appointment.services = [service]
    appointment.save!
    appointment
  end

  it 'inherits business hours when the provider has no custom hours' do
    business_hours

    expect(slots.first).to eq(slot_at(9))
    expect(slots.last).to eq(slot_at(16))
  end

  it 'uses provider hours instead of business hours when customized' do
    business_hours
    provider_hours(opens_at: '10:00', closes_at: '14:00')

    expect(slots.first).to eq(slot_at(10))
    expect(slots.last).to eq(slot_at(13))
    expect(slots).not_to include(slot_at(9))
  end

  it 'returns no slots for an explicitly closed provider day' do
    business_hours
    provider_hours(opens_at: nil, closes_at: nil, is_closed: true)

    expect(slots).to be_empty
  end

  it 'removes business closures from inherited hours' do
    business_hours

    availability_block(
      starts_at: local_time(12),
      ends_at: local_time(14),
      is_available: false
    )

    expect(slots).to include(slot_at(9), slot_at(14))
    expect(slots).not_to include(slot_at(12), slot_at(13))
  end

  it 'does not apply business closures to custom provider hours' do
    business_hours
    provider_hours(opens_at: '10:00', closes_at: '15:00')

    availability_block(
      starts_at: local_time(11),
      ends_at: local_time(13),
      is_available: false
    )

    expect(slots).to include(slot_at(11), slot_at(12))
  end

  it 'allows extra availability on an explicitly closed day' do
    provider_hours(opens_at: nil, closes_at: nil, is_closed: true)

    availability_block(
      user: user,
      starts_at: local_time(10),
      ends_at: local_time(12),
      is_available: true
    )

    expect(slots).to include(slot_at(10), slot_at(11))
  end

  it 'allows extra availability during a business closure' do
    business_hours

    availability_block(
      starts_at: local_time(9),
      ends_at: local_time(17),
      is_available: false
    )

    availability_block(
      user: user,
      starts_at: local_time(10),
      ends_at: local_time(12),
      is_available: true
    )

    expect(slots.first).to eq(slot_at(10))
    expect(slots.last).to eq(slot_at(11))
  end

  it 'gives provider blocked time priority over extra availability' do
    availability_block(
      user: user,
      starts_at: local_time(9),
      ends_at: local_time(13),
      is_available: true
    )

    availability_block(
      user: user,
      starts_at: local_time(10),
      ends_at: local_time(11),
      is_available: false
    )

    expect(slots).to include(slot_at(9), slot_at(11))
    expect(slots).not_to include(slot_at(10))
  end

  it 'merges adjacent availability intervals' do
    provider_hours(opens_at: '09:00', closes_at: '11:00')

    availability_block(
      user: user,
      starts_at: local_time(11),
      ends_at: local_time(13),
      is_available: true
    )

    expect(slots(duration: 180)).to include(slot_at(9))
  end

  it 'requires the entire appointment to fit inside available hours' do
    provider_hours(opens_at: '09:00', closes_at: '10:00')

    expect(slots(duration: 45)).to include(slot_at(9), slot_at(9, 15))
    expect(slots(duration: 45)).not_to include(slot_at(9, 30))
  end

  it 'returns no slots when no working hours or extra availability exist' do
    expect(slots).to be_empty
  end

  it 'rejects zero-duration appointments' do
    expect { slots(duration: 0) }.to raise_error(ArgumentError)
  end

  it 'rejects resources from another account' do
    other_resource = create(:resource, account: create(:account))

    expect do
      slots(selected_resource: other_resource)
    end.to raise_error(ArgumentError, 'Resource must belong to account')
  end

  it 'returns UTC timestamps' do
    business_hours

    expect(slots.first).to eq('2026-11-09T15:00:00Z')
  end

  it 'excludes slots overlapping an appointment using the selected resource' do
    business_hours

    other_provider = create(:user, account: account)

    booked_appointment(
      provider: other_provider,
      booked_resource: resource,
      starts_at: local_time(10)
    )

    expect(slots).to include(slot_at(9), slot_at(11))
    expect(slots).not_to include(slot_at(9, 15), slot_at(10))
  end

  it 'excludes slots when the provider is booked using another resource' do
    business_hours

    another_resource = create(:resource, account: account)

    booked_appointment(
      provider: user,
      booked_resource: another_resource,
      starts_at: local_time(10)
    )

    expect(slots).to include(slot_at(9), slot_at(11))
    expect(slots).not_to include(slot_at(9, 15), slot_at(10))
  end

  it 'ignores canceled appointments when calculating availability' do
    business_hours

    booked_appointment(
      provider: user,
      booked_resource: resource,
      starts_at: local_time(10),
      status: 'canceled'
    )

    expect(slots).to include(slot_at(10))
  end

  it 'excludes appointments that extend into the requested date' do
    provider_hours(opens_at: '00:00', closes_at: '03:00')

    booked_appointment(
      provider: user,
      booked_resource: resource,
      starts_at: local_time(0) - 30.minutes,
      duration: 90
    )

    expect(slots).not_to include(slot_at(0))
    expect(slots).to include(slot_at(1))
  end

  it 'handles the spring daylight-saving transition' do
    travel_to Time.utc(2026, 3, 7, 12) do
      spring_date = Date.new(2026, 3, 8)

      create(
        :working_hour,
        account: account,
        day_of_week: spring_date.wday,
        opens_at: '01:00',
        closes_at: '04:00'
      )

      spring_slots = described_class.new(
        user: user,
        date: spring_date,
        duration_minutes: 120,
        resource: resource
      ).available_slots

      expect(spring_slots).to include('2026-03-08T07:00:00Z')
      expect(spring_slots).not_to include('2026-03-08T08:00:00Z')
    end
  end

  it 'handles the fall daylight-saving transition' do
    travel_to Time.utc(2026, 10, 31, 12) do
      fall_date = Date.new(2026, 11, 1)

      create(
        :working_hour,
        account: account,
        day_of_week: fall_date.wday,
        opens_at: '00:00',
        closes_at: '03:00'
      )

      fall_slots = described_class.new(
        user: user,
        date: fall_date,
        duration_minutes: 60,
        resource: resource
      ).available_slots

      expect(fall_slots).to include(
        '2026-11-01T05:00:00Z',
        '2026-11-01T06:00:00Z',
        '2026-11-01T07:00:00Z',
        '2026-11-01T08:00:00Z'
      )
    end
  end

  it 'handles extra availability crossing midnight' do
    availability_block(
      user: user,
      starts_at: local_time(23),
      ends_at: local_time(23) + 3.hours,
      is_available: true
    )

    expect(slots(duration: 60)).to include(slot_at(23))
    expect(slots(duration: 60)).not_to include(slot_at(0))
  end
end
