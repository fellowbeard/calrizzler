require 'rails_helper'

RSpec.describe 'Api::V1::Dashboard', type: :request do
  let!(:account) { Account.create!(business_name: 'Acme Consulting') }
  let!(:user) do
    account.users.create!(
      first_name: 'Owner',
      last_name: 'Example',
      email: 'owner@example.com',
      role: 'owner',
      password: 'password',
      password_confirmation: 'password'
    )
  end
  let!(:client) { account.clients.create!(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', user: user) }
  let!(:resource) { account.resources.create!(name: 'Room 1') }
  let!(:service) { account.services.create!(title: 'Consulting', price: 180.0, duration_minutes: 60, user: user) }
  let!(:appointment) do
    appointment = account.appointments.new(scheduled_at: 2.days.from_now, status: 'scheduled', user: user,
                                           client: client, resource: resource, duration_minutes: 60)
    appointment.services << service
    appointment.save!
    appointment
  end

  it 'returns dashboard data for the authenticated user' do
    get '/api/v1/dashboard', headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(json).to include(
      'user',
      'account',
      'services',
      'clients',
      'recent_clients',
      'appointments',
      'appointments_count',
      'recent_appointments'
    )

    expect(json['user']['email']).to eq(user.email)
    expect(json['account']['business_name']).to eq(account.business_name)
    expect(json['services']).to be_an(Array)
    expect(json['services'].first['title']).to eq(service.title)
    expect(json['clients'].first['id']).to eq(client.id)
    expect(json['appointments_count']).to eq(1)
    expect(json['appointments'].first['id']).to eq(appointment.id)
  end

  it 'rejects access without a valid token' do
    get '/api/v1/dashboard'

    expect(response).to have_http_status(:unauthorized)
    expect(json.dig('error', 'message')).to eq('You must be logged in to do that.')
  end
end
