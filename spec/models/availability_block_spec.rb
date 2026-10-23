require 'rails_helper'

RSpec.describe AvailabilityBlock, type: :model do
  let(:user) { create(:user) }

  def availability_block(attributes = {})
    described_class.new({
      user: user,
      account: user.account,
      starts_at: Time.zone.parse('2026-11-02 09:00'),
      ends_at: Time.zone.parse('2026-11-02 17:00'),
    }.merge(attributes))
  end

  it 'accepts a valid availability block' do
    expect(availability_block).to be_valid
  end

  it 'rejects a missing start time' do
    expect(availability_block(starts_at: nil)).not_to be_valid
  end

  it 'rejects a missing end time' do
    expect(availability_block(ends_at: nil)).not_to be_valid
  end

  it 'rejects an end time before the start time' do
    block = availability_block(
      ends_at: Time.zone.parse('2026-11-02 08:00')
    )

    expect(block).not_to be_valid
  end

  it 'rejects identical start and end times' do
    block = availability_block(
      ends_at: Time.zone.parse('2026-11-02 09:00')
    )

    expect(block).not_to be_valid
  end

  it 'allows blocks spanning multiple days' do
    block = availability_block(
      ends_at: Time.zone.parse('2026-11-06 17:00')
    )

    expect(block).to be_valid
  end

  it 'allows blocks outside normal business hours' do
    block = availability_block(
      starts_at: Time.zone.parse('2026-11-02 20:00'),
      ends_at: Time.zone.parse('2026-11-02 23:00')
    )

    expect(block).to be_valid
  end
end
