require 'rails_helper'

RSpec.describe WorkingHour, type: :model do
  let(:account) { Account.create!(business_name: 'Test Business', timezone: 'America/Chicago') }

  def create_hours(day:, opens:, closes:)
    account.working_hours.create!(
      day_of_week: day,
      opens_at: opens,
      closes_at: closes
    )
  end

  it 'allows valid working hours' do
    hours = account.working_hours.build(
      day_of_week: 1,
      opens_at: '09:00',
      closes_at: '17:00'
    )

    expect(hours).to be_valid
  end

  it 'rejects invalid weekdays' do
    hours = account.working_hours.build(
      day_of_week: 7,
      opens_at: '09:00',
      closes_at: '17:00'
    )

    expect(hours).not_to be_valid
  end

  it 'rejects closing before opening' do
    hours = account.working_hours.build(
      day_of_week: 1,
      opens_at: '17:00',
      closes_at: '09:00'
    )

    expect(hours).not_to be_valid
  end

  it 'rejects overlapping intervals' do
    create_hours(day: 1, opens: '09:00', closes: '13:00')

    hours = account.working_hours.build(
      day_of_week: 1,
      opens_at: '12:00',
      closes_at: '17:00'
    )

    expect(hours).not_to be_valid
    expect(hours.errors.full_messages).to include('Working hours cannot overlap')
  end

  it 'allows adjacent intervals' do
    create_hours(day: 1, opens: '09:00', closes: '12:00')

    hours = account.working_hours.build(
      day_of_week: 1,
      opens_at: '12:00',
      closes_at: '17:00'
    )

    expect(hours).to be_valid
  end
end
