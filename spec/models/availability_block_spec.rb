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

  it 'accepts blocked time and one-time extra availability' do
    expect(availability_block(is_available: false)).to be_valid
    expect(availability_block(is_available: true)).to be_valid
  end

  it 'defaults to blocked time' do
    expect(availability_block.is_available).to be(false)
  end

  it 'requires valid start and end times' do
    start_time = Time.zone.parse('2026-11-02 09:00')

    [
      { starts_at: nil },
      { ends_at: nil },
      { ends_at: start_time },
      { ends_at: start_time - 1.hour },
    ].each do |attributes|
      expect(availability_block(attributes)).not_to be_valid
    end
  end

  it 'allows multi-day exceptions and times outside business hours' do
    expect(
      availability_block(ends_at: Time.zone.parse('2026-11-06 17:00'))
    ).to be_valid

    expect(
      availability_block(
        starts_at: Time.zone.parse('2026-11-02 20:00'),
        ends_at: Time.zone.parse('2026-11-02 23:00'),
        is_available: true
      )
    ).to be_valid
  end

  it 'allows business-wide closures but not business-wide extra availability' do
    closure = availability_block(user: nil, is_available: false)
    extra_hours = availability_block(user: nil, is_available: true)

    expect(closure).to be_valid
    expect(extra_hours).not_to be_valid
    expect(extra_hours.errors[:is_available]).to be_present
  end

  it 'rejects a provider belonging to another account' do
    block = availability_block(account: create(:account))

    expect(block).not_to be_valid
  end
end
