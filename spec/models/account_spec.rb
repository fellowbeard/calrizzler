require 'rails_helper'

RSpec.describe Account, type: :model do
  it 'requires a valid timezone' do
    account = Account.new(business_name: 'Acme', timezone: 'Invalid/Timezone')

    expect(account).not_to be_valid
    expect(account.errors[:timezone]).to include('is not included in the list')
  end

  it 'accepts a valid timezone' do
    account = Account.new(business_name: 'Acme', timezone: 'America/New_York')

    expect(account).to be_valid
  end

  it 'requires a business name' do
    account = Account.new

    expect(account).not_to be_valid
    expect(account.errors[:business_name]).to include("can't be blank")
  end
end
