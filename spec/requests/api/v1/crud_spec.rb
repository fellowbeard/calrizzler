require 'rails_helper'

RSpec.describe 'Api::V1 CRUD and authorization', type: :request do
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

  describe 'clients' do
    it 'creates and updates a client for write users' do
      post '/api/v1/clients', headers: auth_headers(owner), params: {
        client: { first_name: 'New', last_name: 'Client', email: 'new@example.com', phone: '555-9876' },
      }

      expect(response).to have_http_status(:created)
      expect(json['first_name']).to eq('New')

      patch "/api/v1/clients/#{client.id}", headers: auth_headers(owner), params: { client: { phone: '555-0000' } }
      expect(response).to have_http_status(:ok)
      expect(json['phone']).to eq('555-0000')
    end

    it 'prevents read-only users from creating clients' do
      post '/api/v1/clients', headers: auth_headers(read_only_user), params: {
        client: { first_name: 'Block', last_name: 'User', email: 'blocked@example.com' },
      }

      expect(response).to have_http_status(:forbidden)
      expect(json.dig('error', 'message')).to eq('Read-only users cannot make changes.')
    end

    it 'returns client details and allows deletion' do
      get "/api/v1/clients/#{client.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
      expect(json['email']).to eq(client.email)

      delete "/api/v1/clients/#{client.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'resources' do
    it 'supports create, update, and destroy for write users' do
      post '/api/v1/resources', headers: auth_headers(staff), params: { resource: { name: 'Desk 1' } }
      expect(response).to have_http_status(:created)
      expect(json['name']).to eq('Desk 1')

      resource_id = json['id']
      patch "/api/v1/resources/#{resource_id}", headers: auth_headers(owner), params: { resource: { name: 'Desk 2' } }
      expect(response).to have_http_status(:ok)
      expect(json['name']).to eq('Desk 2')

      delete "/api/v1/resources/#{resource_id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:no_content)
    end

    it 'blocks read-only users from modifying resources' do
      post '/api/v1/resources', headers: auth_headers(read_only_user), params: { resource: { name: 'Blocked' } }
      expect(response).to have_http_status(:forbidden)
      expect(json.dig('error', 'message')).to eq('Read-only users cannot make changes.')
    end
  end

  describe 'appointments' do
    it 'creates an appointment with a service and resource' do
      post '/api/v1/appointments', headers: auth_headers(owner), params: {
        appointment: {
          client_id: client.id,
          resource_id: resource.id,
          scheduled_at: 4.days.from_now.iso8601,
          status: 'scheduled',
          service_ids: [service.id],
        },
      }

      expect(response).to have_http_status(:created)
      expect(json['client_id']).to eq(client.id)
      expect(json['services']).to be_an(Array)
      expect(json['services'].first['title']).to eq(service.title)
    end

    it 'rejects overlapping appointments for the same resource' do
      create(:appointment, account: account, user: owner, client: client, resource: resource, services: [service],
                           scheduled_at: 5.days.from_now)

      post '/api/v1/appointments', headers: auth_headers(owner), params: {
        appointment: {
          client_id: client.id,
          resource_id: resource.id,
          scheduled_at: (5.days.from_now + 15.minutes).iso8601,
          status: 'scheduled',
          service_ids: [service.id],
        },
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig('error', 'details', 'base')).to include('Resource is already booked at the scheduled time')
    end

    it 'prevents read-only users from creating appointments' do
      post '/api/v1/appointments', headers: auth_headers(read_only_user), params: {
        appointment: {
          client_id: client.id,
          resource_id: resource.id,
          scheduled_at: 6.days.from_now.iso8601,
          status: 'scheduled',
          service_ids: [service.id],
        },
      }

      expect(response).to have_http_status(:forbidden)
      expect(json.dig('error', 'message')).to eq('Read-only users cannot make changes.')
    end
  end

  describe 'services' do
    it 'returns a list of services and allows updates' do
      get '/api/v1/services', headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
      expect(json).to be_an(Array)

      patch "/api/v1/services/#{service.id}", headers: auth_headers(owner),
                                              params: { service: { title: 'Updated Consultation' } }
      expect(response).to have_http_status(:ok)
      expect(json['title']).to eq('Updated Consultation')
    end

    it 'blocks read-only users from deleting services' do
      delete "/api/v1/services/#{service.id}", headers: auth_headers(read_only_user)
      expect(response).to have_http_status(:forbidden)
      expect(json.dig('error', 'message')).to eq('Read-only users cannot make changes.')
    end
  end

  describe 'notes' do
    it 'returns all notes for the current account' do
      create(:note, client: client, user: owner, body: 'Another note')

      get '/api/v1/notes', headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json).to be_an(Array)
      expect(json.pluck('body')).to include('Initial note', 'Another note')
    end

    it 'returns a specific note' do
      get "/api/v1/notes/#{note.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json['id']).to eq(note.id)
      expect(json['body']).to eq('Initial note')
    end

    it 'creates a note for a valid client in the account' do
      post '/api/v1/notes', headers: auth_headers(owner), params: {
        note: { client_id: client.id, body: 'New note about the client' },
      }

      expect(response).to have_http_status(:created)
      expect(json['body']).to eq('New note about the client')
      expect(json['client_id']).to eq(client.id)
    end

    it 'updates a note body for write users' do
      patch "/api/v1/notes/#{note.id}", headers: auth_headers(owner), params: {
        note: { body: 'Updated note' },
      }

      expect(response).to have_http_status(:ok)
      expect(json['body']).to eq('Updated note')
      expect(note.reload.body).to eq('Updated note')
    end

    it 'destroys a note for write users' do
      delete "/api/v1/notes/#{note.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:no_content)
      expect(Note.find_by(id: note.id)).to be_nil
    end
  end
end
