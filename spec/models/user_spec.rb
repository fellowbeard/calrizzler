require 'rails_helper'

RSpec.describe User, type: :model do
  let(:account) { Account.create!(business_name: 'Acme') }

  it 'requires an email' do
    user = account.users.new(first_name: 'Jane', last_name: 'Doe', role: 'owner', password: 'password',
                             password_confirmation: 'password')

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end

  it 'requires unique email addresses' do
    account.users.create!(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', role: 'owner',
                          password: 'password', password_confirmation: 'password')
    duplicate = account.users.new(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', role: 'owner',
                                  password: 'password', password_confirmation: 'password')

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include('has already been taken')
  end

  it 'only accepts allowed roles' do
    user = account.users.new(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', role: 'invalid',
                             password: 'password', password_confirmation: 'password')

    expect(user).not_to be_valid
    expect(user.errors[:role]).to include('is not included in the list')
  end

  it 'knows when a user can write' do
    owner = account.users.create!(first_name: 'Owner', last_name: 'One', email: 'owner@example.com', role: 'owner',
                                  password: 'password', password_confirmation: 'password')
    staff = account.users.create!(first_name: 'Staff', last_name: 'One', email: 'staff@example.com', role: 'staff',
                                  password: 'password', password_confirmation: 'password')
    read_only = account.users.create!(first_name: 'Read', last_name: 'Only', email: 'read@example.com',
                                      role: 'read_only', password: 'password', password_confirmation: 'password')

    expect(owner.can_write?).to be true
    expect(staff.can_write?).to be true
    expect(read_only.can_write?).to be false
  end

  it 'identifies each role' do
    owner = build(:user, account: account, role: 'owner')
    staff = build(:user, account: account, role: 'staff')
    read_only = build(:user, account: account, role: 'read_only')

    expect(owner).to be_owner
    expect(owner).not_to be_staff
    expect(owner).not_to be_read_only
    expect(staff).to be_staff
    expect(staff).not_to be_owner
    expect(staff).not_to be_read_only
    expect(read_only).to be_read_only
    expect(read_only).not_to be_owner
    expect(read_only).not_to be_staff
  end
end
