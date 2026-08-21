require 'rails_helper'

RSpec.describe Resource, type: :model do
  let(:account) { create(:account) }

  it 'validates presence of a name' do
    resource = Resource.new

    expect(resource).not_to be_valid
    expect(resource.errors[:name]).to include("can't be blank")
  end

  it 'normalizes number words in the name' do
    resource = create(:resource, account: account, name: 'room twenty one')

    expect(resource.name).to eq('Room 21')
  end

  it 'requires names to be unique within an account' do
    create(:resource, account: account, name: 'Room A')
    duplicate = build(:resource, account: account, name: 'Room A')

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to include('has already been taken')
  end

  it 'allows the same name in different accounts' do
    create(:resource, account: account, name: 'Room A')
    other_resource = build(:resource, account: create(:account), name: 'Room A')

    expect(other_resource).to be_valid
  end
end
