require 'rails_helper'

RSpec.describe Appointment, type: :model do
  let(:account) { Account.create!(business_name: 'Acme') }
  let(:user) do
    account.users.create!(first_name: 'Owner', last_name: 'One', email: 'owner@example.com', role: 'owner',
                          password: 'password', password_confirmation: 'password')
  end
  let(:client) { account.clients.create!(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', user: user) }
  let(:resource) { account.resources.create!(name: 'Room A') }
  let(:service) { account.services.create!(title: 'Consulting', price: 100.0, duration_minutes: 45, user: user) }

  it 'requires a scheduled_at time' do
    appointment = account.appointments.new(status: 'scheduled', user: user, client: client, resource: resource)
    appointment.services << service

    expect(appointment).not_to be_valid
    expect(appointment.errors[:scheduled_at]).to include("can't be blank")
  end

  it 'requires a valid status' do
    appointment = account.appointments.new(scheduled_at: 1.hour.from_now, status: 'invalid', user: user,
                                           client: client, resource: resource)
    appointment.services << service

    expect(appointment).not_to be_valid
    expect(appointment.errors[:status]).to include('is not included in the list')
  end

  it 'requires at least one service' do
    appointment = account.appointments.new(scheduled_at: 1.hour.from_now, status: 'scheduled', user: user,
                                           client: client, resource: resource)

    expect(appointment).not_to be_valid
    expect(appointment.errors[:services]).to include('must include at least one service')
  end

  it 'rejects scheduled appointments in the past' do
    appointment = account.appointments.new(scheduled_at: 1.hour.ago, status: 'scheduled', user: user, client: client,
                                           resource: resource)
    appointment.services << service

    expect(appointment).not_to be_valid
    expect(appointment.errors[:scheduled_at]).to include("can't be in the past")
  end

  it 'prevents double-booking a resource' do
    existing = account.appointments.new(scheduled_at: 1.day.from_now, status: 'scheduled', user: user, client: client,
                                        resource: resource)
    existing.services << service
    existing.save!

    new_appointment = account.appointments.new(scheduled_at: 1.day.from_now + 15.minutes, status: 'scheduled',
                                               user: user, client: client, resource: resource)
    new_appointment.services << service

    expect(new_appointment).not_to be_valid
    expect(new_appointment.errors[:base]).to include('Resource is already booked at the scheduled time')
  end

  it 'computes reservation time from service duration' do
    appointment = account.appointments.new(scheduled_at: 1.hour.from_now, status: 'scheduled', user: user,
                                           client: client, resource: resource)
    appointment.services << service
    appointment.save!

    expect(appointment.blocking_reservation_time).to eq(45)
  end
end
