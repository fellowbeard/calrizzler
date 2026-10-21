require 'rails_helper'

RSpec.describe 'Api::V1::Dashboard', type: :request do
  let!(:account) do
    Account.create!(
      business_name: 'Acme Consulting'
    )
  end

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

  let!(:staff) do
    account.users.create!(
      first_name: 'Staff',
      last_name: 'Example',
      email: 'staff@example.com',
      role: 'staff',
      password: 'password',
      password_confirmation: 'password'
    )
  end

  let!(:client) do
    account.clients.create!(
      first_name: 'Jane',
      last_name: 'Doe',
      email: 'jane@example.com',
      user: user
    )
  end

  let!(:staff_client) do
    account.clients.create!(
      first_name: 'John',
      last_name: 'Smith',
      email: 'john@example.com',
      user: staff
    )
  end

  let!(:resource) do
    account.resources.create!(
      name: 'Room 1'
    )
  end

  let!(:service) do
    account.services.create!(
      title: 'Consulting',
      price: 180.0,
      duration_minutes: 60
    )
  end

  let!(:staff_service) do
    account.services.create!(
      title: 'Staff Service',
      price: 100.0,
      duration_minutes: 30
    )
  end

  before do
    UserService.create!(
      user: user,
      service: service,
      price: service.price
    )

    UserService.create!(
      user: staff,
      service: staff_service,
      price: staff_service.price
    )
  end

  let!(:appointment) do
    appointment = account.appointments.new(
      scheduled_at: 2.days.from_now,
      status: 'scheduled',
      user: user,
      client: client,
      resource: resource,
      duration_minutes: 60
    )

    appointment.services << service
    appointment.save!
    appointment
  end

  let!(:staff_appointment) do
    appointment = account.appointments.new(
      scheduled_at: 3.days.from_now,
      status: 'scheduled',
      user: staff,
      client: staff_client,
      resource: resource,
      duration_minutes: 30
    )

    appointment.services << staff_service
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
      'resources',
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

    # appointments_count is scoped to the authenticated user.
    expect(json['appointments_count']).to eq(1)

    # The calendar contains appointments for the entire account.
    expect(json['appointments'].length).to eq(2)

    own_appointment = json['appointments'].find do |item|
      item['id'] == appointment.id
    end

    expect(own_appointment).to be_present

    shared_appointment = json['appointments'].find do |item|
      item['id'] == staff_appointment.id
    end

    expect(shared_appointment).to be_present

    expect(shared_appointment['user']).to include(
      'id' => staff.id,
      'first_name' => 'Staff',
      'last_name' => 'Example'
    )

    expect(shared_appointment['resource']).to include(
      'id' => resource.id,
      'name' => resource.name
    )
  end

  it 'excludes archived services but preserves them on existing appointments' do
    original_price = appointment.appointment_services.first.price_at_booking

    service.archive!

    get '/api/v1/dashboard', headers: auth_headers(user)

    expect(response).to have_http_status(:ok)

    # Archived services should not appear in the available catalog.
    service_ids = json['services'].pluck('id')

    expect(service_ids).not_to include(service.id)
    expect(service_ids).to include(staff_service.id)

    # Existing appointments should retain their booked services.
    own_appointment = json['appointments'].find do |item|
      item['id'] == appointment.id
    end

    expect(own_appointment).to be_present

    booked_service = own_appointment['services'].find do |item|
      item['id'] == service.id
    end

    expect(booked_service).to be_present
    expect(booked_service['title']).to eq(service.title)
    expect(booked_service['price'].to_d).to eq(original_price)
  end

  it 'rejects access without a valid token' do
    get '/api/v1/dashboard'

    expect(response).to have_http_status(:unauthorized)
    expect(json.dig('error', 'message')).to eq(
      'You must be logged in to do that.'
    )
  end
end
