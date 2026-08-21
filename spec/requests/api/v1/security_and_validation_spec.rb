require 'rails_helper'

RSpec.describe 'Api::V1 security and validation boundaries', type: :request do
  let!(:account) { create(:account) }
  let!(:owner) { create(:user, account: account) }
  let!(:staff) { create(:user, :staff, account: account) }
  let!(:read_only_user) { create(:user, :read_only, account: account) }
  let!(:client) { create(:client, account: account, user: owner) }
  let!(:resource) { create(:resource, account: account, name: 'Conference Room') }
  let!(:service) do
    create(:service, account: account, user: owner, title: 'Consultation', price: 140.0, duration_minutes: 45)
  end
  let!(:appointment) do
    create(:appointment, account: account, user: owner, client: client, resource: resource, services: [service],
                         scheduled_at: 3.days.from_now)
  end
  let!(:note) { create(:note, client: client, user: owner, body: 'Initial note') }

  describe 'authentication' do
    it 'rejects unauthenticated access to every protected collection endpoint' do
      protected_gets = [
        '/api/v1/me',
        '/api/v1/dashboard',
        '/api/v1/account',
        '/api/v1/clients',
        '/api/v1/resources',
        '/api/v1/services',
        '/api/v1/appointments',
        '/api/v1/notes',
        '/api/v1/users',
      ]

      protected_gets.each do |path|
        get path

        expect(response).to have_http_status(:unauthorized), "expected #{path} to require authentication"
        expect(json.dig('error', 'code')).to eq('unauthorized')
      end
    end

    it 'rejects malformed tokens' do
      get '/api/v1/dashboard', headers: { 'Authorization' => 'Bearer not-a-jwt' }

      expect(response).to have_http_status(:unauthorized)
      expect(json.dig('error', 'message')).to eq('You must be logged in to do that.')
    end

    it 'rejects expired tokens' do
      token = JwtService.encode({ user_id: owner.id }, 1.hour.ago)

      get '/api/v1/dashboard', headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
      expect(json.dig('error', 'code')).to eq('unauthorized')
    end
  end

  describe 'validation errors' do
    it 'returns structured errors when a client is missing a required field' do
      post '/api/v1/clients', headers: auth_headers(owner), params: {
        client: { last_name: 'Missing First Name', email: 'missing@example.com' },
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig('error', 'code')).to eq('validation_failed')
      expect(json.dig('error', 'details', 'first_name')).to include("First name can't be blank")
    end

    it 'returns structured errors for an invalid resource' do
      post '/api/v1/resources', headers: auth_headers(owner), params: { resource: { name: '' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig('error', 'details', 'name')).to include("Name can't be blank")
    end

    it 'returns structured errors for an invalid service' do
      post '/api/v1/services', headers: auth_headers(owner), params: {
        service: { title: '', price: -1, duration_minutes: 30 },
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig('error', 'details', 'title')).to include("Title can't be blank")
      expect(json.dig('error', 'details', 'price')).to include('Price must be greater than or equal to 0')
    end

    it 'returns structured errors for an invalid appointment' do
      post '/api/v1/appointments', headers: auth_headers(owner), params: {
        appointment: {
          client_id: client.id,
          resource_id: resource.id,
          scheduled_at: 2.days.from_now.iso8601,
          status: 'invalid',
          duration_minutes: 45,
          service_ids: [],
        },
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig('error', 'details', 'status')).to include('Status is not included in the list')
      expect(json.dig('error', 'details', 'services')).to include('Services must include at least one')
    end

    it 'returns a bad request for a missing request object' do
      post '/api/v1/clients', headers: auth_headers(owner), params: {}

      expect(response).to have_http_status(:bad_request)
      expect(json.dig('error', 'code')).to eq('bad_request')
    end
  end

  describe 'role permissions' do
    it 'allows staff to update their own client but not another staff member client' do
      staff_client = create(:client, account: account, user: staff)

      patch "/api/v1/clients/#{staff_client.id}", headers: auth_headers(staff), params: {
        client: { phone: '555-1111' },
      }
      expect(response).to have_http_status(:ok)

      patch "/api/v1/clients/#{client.id}", headers: auth_headers(staff), params: {
        client: { phone: '555-2222' },
      }
      expect(response).to have_http_status(:forbidden)
      expect(json.dig('error', 'message')).to eq('You can only change your own clients.')
    end

    it 'allows only owners to update the account' do
      patch '/api/v1/account', headers: auth_headers(staff), params: { account: { business_name: 'Blocked' } }

      expect(response).to have_http_status(:forbidden)
      expect(json.dig('error', 'message')).to eq('Only account owners can do that.')
    end

    it 'allows an owner to update the account' do
      patch '/api/v1/account', headers: auth_headers(owner), params: { account: { business_name: 'Updated Acme' } }

      expect(response).to have_http_status(:ok)
      expect(json['business_name']).to eq('Updated Acme')
      expect(account.reload.business_name).to eq('Updated Acme')
    end

    it 'prevents read-only users from creating, updating, or deleting resources' do
      operations = [
        [:post, '/api/v1/clients', { client: { first_name: 'Blocked', last_name: 'Client' } },
         'Read-only users cannot make changes.'],
        [:patch, "/api/v1/clients/#{client.id}", { client: { phone: '555-0001' } },
         'Read-only users cannot make changes.'],
        [:delete, "/api/v1/clients/#{client.id}", {}, 'Read-only users cannot make changes.'],
        [:post, '/api/v1/resources', { resource: { name: 'Blocked Room' } }, 'Read-only users cannot make changes.'],
        [:patch, "/api/v1/resources/#{resource.id}", { resource: { name: 'Blocked Room' } },
         'Read-only users cannot make changes.'],
        [:delete, "/api/v1/resources/#{resource.id}", {}, 'Read-only users cannot make changes.'],
        [:post, '/api/v1/services', { service: { title: 'Blocked Service', price: 10 } },
         'Read-only users cannot make changes.'],
        [:patch, "/api/v1/services/#{service.id}", { service: { title: 'Blocked Service' } },
         'Read-only users cannot make changes.'],
        [:delete, "/api/v1/services/#{service.id}", {}, 'Read-only users cannot make changes.'],
        [:post, '/api/v1/appointments', { appointment: {
          client_id: client.id,
          resource_id: resource.id,
          scheduled_at: 4.days.from_now.iso8601,
          duration_minutes: 45,
          service_ids: [service.id],
        } }, 'Read-only users cannot make changes.'],
        [:patch, "/api/v1/appointments/#{appointment.id}", { appointment: { status: 'completed' } },
         'Read-only users cannot make changes.'],
        [:delete, "/api/v1/appointments/#{appointment.id}", {}, 'Read-only users cannot make changes.'],
        [:post, '/api/v1/notes', { note: { client_id: client.id, body: 'Blocked note' } },
         'Read-only users cannot make changes.'],
        [:patch, "/api/v1/notes/#{note.id}", { note: { body: 'Blocked note' } },
         'Read-only users cannot make changes.'],
        [:delete, "/api/v1/notes/#{note.id}", {}, 'Read-only users cannot make changes.'],
        [:patch, '/api/v1/account', { account: { business_name: 'Blocked Account' } },
         'Only account owners can do that.'],
        [:post, '/api/v1/users', { user: {
          first_name: 'Blocked',
          last_name: 'User',
          email: 'blocked-user@example.com',
          role: 'staff',
          password: 'password',
          password_confirmation: 'password',
        } }, 'Only account owners can do that.'],
        [:patch, "/api/v1/users/#{read_only_user.id}", { user: { first_name: 'Blocked' } },
         'Read-only users cannot make changes.'],
        [:delete, "/api/v1/users/#{staff.id}", {}, 'Only account owners can do that.'],
      ]

      operations.each do |verb, path, params, expected_message|
        public_send(verb, path, headers: auth_headers(read_only_user), params: params)

        expect(response).to have_http_status(:forbidden), "expected #{verb.upcase} #{path} to be forbidden"
        expect(json.dig('error', 'message')).to eq(expected_message)
      end
    end

    it 'allows only owners to change roles and delete users' do
      patch "/api/v1/users/#{owner.id}/update_role", headers: auth_headers(staff), params: {
        user: { role: 'staff' },
      }
      expect(response).to have_http_status(:forbidden)

      delete "/api/v1/users/#{staff.id}", headers: auth_headers(staff)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'account isolation' do
    let!(:other_account) { create(:account) }
    let!(:other_user) { create(:user, account: other_account) }
    let!(:other_client) { create(:client, account: other_account, user: other_user) }
    let!(:other_resource) { create(:resource, account: other_account, name: 'Other Room') }
    let!(:other_service) { create(:service, account: other_account, user: other_user) }
    let!(:other_appointment) do
      create(:appointment, account: other_account, user: other_user, client: other_client, resource: other_resource,
                           services: [other_service], scheduled_at: 3.days.from_now)
    end
    let!(:other_note) { create(:note, client: other_client, user: other_user, body: 'Private note') }

    it 'does not expose records belonging to another account' do
      [
        "/api/v1/clients/#{other_client.id}",
        "/api/v1/resources/#{other_resource.id}",
        "/api/v1/services/#{other_service.id}",
        "/api/v1/appointments/#{other_appointment.id}",
        "/api/v1/notes/#{other_note.id}",
        "/api/v1/users/#{other_user.id}",
      ].each do |path|
        get path, headers: auth_headers(owner)

        expect(response).to have_http_status(:not_found), "expected #{path} to be account-isolated"
        expect(json.dig('error', 'code')).to eq('not_found')
      end
    end
  end
end
