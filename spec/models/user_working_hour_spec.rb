require 'rails_helper'

RSpec.describe UserWorkingHour, type: :model do
  let(:user) { create(:user) }

  def working_hour(attributes = {})
    described_class.new({
      user: user,
      day_of_week: 1,
      opens_at: '09:00',
      closes_at: '17:00',
    }.merge(attributes))
  end

  it 'accepts valid working hours' do
    expect(working_hour).to be_valid
  end

  it 'rejects overlapping hours' do
    working_hour.save!

    overlapping = working_hour(
      opens_at: '12:00',
      closes_at: '18:00'
    )

    expect(overlapping).not_to be_valid
  end

  it 'allows adjacent working hours' do
    working_hour.save!

    adjacent = working_hour(
      opens_at: '17:00',
      closes_at: '19:00'
    )

    expect(adjacent).to be_valid
  end

  it 'allows an explicitly closed day' do
    closed = working_hour(
      opens_at: nil,
      closes_at: nil,
      is_closed: true
    )

    expect(closed).to be_valid
  end

  it 'rejects working hours on a closed day' do
    working_hour(
      opens_at: nil,
      closes_at: nil,
      is_closed: true
    ).save!

    expect(working_hour).not_to be_valid
  end

  it 'rejects closing a day with existing hours' do
    working_hour.save!

    closed = working_hour(
      opens_at: nil,
      closes_at: nil,
      is_closed: true
    )

    expect(closed).not_to be_valid
  end

  it 'allows different providers to work the same hours' do
    working_hour.save!

    another_provider = working_hour(user: create(:user))

    expect(another_provider).to be_valid
  end
end
