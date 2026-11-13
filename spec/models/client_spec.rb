require 'rails_helper'

RSpec.describe Client, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  it 'title-cases names' do
    client = create(:client, account: account, user: user, first_name: 'jane', last_name: 'doe')

    expect([client.first_name, client.last_name]).to eq(['Jane', 'Doe'])
  end

  it 'does not turn number words in names into digits' do
    client = create(:client, account: account, user: user, first_name: 'ten', last_name: 'one')

    expect([client.first_name, client.last_name]).to eq(['Ten', 'One'])
  end
end
