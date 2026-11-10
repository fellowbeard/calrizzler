require 'rails_helper'

RSpec.describe 'Api::V1 CRUD and authorization', type: :request do
  let!(:account) { create(:account) }
  let!(:owner) { create(:user, account: account) }
  let!(:staff) { create(:user, :staff, account: account) }
  let!(:read_only_user) { create(:user, :read_only, account: account) }
  let!(:client) { create(:client, account: account, user: owner) }
  let!(:resource) { create(:resource, account: account, name: 'Conference Room') }
  let!(:service) do
    create(:service, account: account, title: 'Consultation', price: 140.0, duration_minutes: 45)
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

    it 'searches clients by name, email, and phone' do
      matching_client = create(
        :client,
        account: account,
        user: owner,
        first_name: 'Penelope',
        last_name: 'Smith',
        email: 'penelope@example.com',
        phone: '504-555-1234'
      )

      create(
        :client,
        account: account,
        user: owner,
        first_name: 'Robert',
        last_name: 'Jones',
        email: 'robert@example.com',
        phone: '504-555-9999'
      )

      ['penelope', 'SMITH', 'Penelope Smith', 'penelope@example.com', '504-555-1234'].each do |search|
        get '/api/v1/clients',
            headers: auth_headers(owner),
            params: { search: search }

        expect(json.pluck('id')).to eq([matching_client.id]), "Failed search: #{search}"

        expect(response).to have_http_status(:ok)
        expect(json.pluck('id')).to eq([matching_client.id])
      end
    end

    it 'returns clients alphabetically when no search is provided' do
      zulu = create(:client, account: account, user: owner, first_name: 'Zoe', last_name: 'Zulu')
      alpha = create(:client, account: account, user: owner, first_name: 'Amy', last_name: 'Alpha')

      get '/api/v1/clients', headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)

      ids = json.pluck('id')

      expect(ids.index(alpha.id)).to be < ids.index(zulu.id)
    end

    it 'does not expose another user clients in search results' do
      other_client = create(
        :client,
        account: account,
        user: staff,
        first_name: 'Private',
        last_name: 'Customer'
      )

      get '/api/v1/clients',
          headers: auth_headers(owner),
          params: { search: 'Private' }

      expect(response).to have_http_status(:ok)
      expect(json.pluck('id')).not_to include(other_client.id)
    end

    it 'returns an empty array when no clients match' do
      get '/api/v1/clients',
          headers: auth_headers(owner),
          params: { search: 'NonexistentCustomer123' }

      expect(response).to have_http_status(:ok)
      expect(json).to eq([])
    end

    it 'creates a client with an address' do
      post '/api/v1/clients',
           headers: auth_headers(owner),
           params: {
             client: {
               first_name: 'Jane',
               last_name: 'Smith',
               address_line1: '123 Main Street',
               address_line2: 'Apt 4',
               city: 'New Orleans',
               state: 'LA',
               postal_code: '70115',
             },
           }

      expect(response).to have_http_status(:created)
      expect(json).to include(
        'address_line1' => '123 Main Street',
        'address_line2' => 'Apt 4',
        'city' => 'New Orleans',
        'state' => 'LA',
        'postal_code' => '70115'
      )

      created_client = Client.find(json['id'])
      expect(created_client.address_line1).to eq('123 Main Street')
    end

    it 'updates and returns a client address' do
      patch "/api/v1/clients/#{client.id}",
            headers: auth_headers(owner),
            params: {
              client: {
                address_line1: '456 Oak Street',
                city: 'New Orleans',
                state: 'LA',
                postal_code: '70118',
              },
            }

      expect(response).to have_http_status(:ok)
      expect(json).to include(
        'address_line1' => '456 Oak Street',
        'city' => 'New Orleans',
        'state' => 'LA',
        'postal_code' => '70118'
      )

      get "/api/v1/clients/#{client.id}",
          headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json['address_line1']).to eq('456 Oak Street')
      expect(json['postal_code']).to eq('70118')
    end
  end

  describe 'resources' do
    it 'supports create, update, and destroy for owners' do
      post '/api/v1/resources',
           headers: auth_headers(owner),
           params: { resource: { name: 'Desk 1' } }

      expect(response).to have_http_status(:created)
      expect(json['name']).to eq('Desk 1')

      resource_id = json['id']

      patch "/api/v1/resources/#{resource_id}",
            headers: auth_headers(owner),
            params: { resource: { name: 'Desk 2' } }

      expect(response).to have_http_status(:ok)
      expect(json['name']).to eq('Desk 2')

      delete "/api/v1/resources/#{resource_id}",
             headers: auth_headers(owner)

      expect(response).to have_http_status(:no_content)
    end

    it 'blocks staff users from modifying resources' do
      post '/api/v1/resources',
           headers: auth_headers(staff),
           params: { resource: { name: 'Blocked' } }

      expect(response).to have_http_status(:forbidden)
      expect(json.dig('error', 'message')).to eq('Only account owners can do that.')
    end

    it 'blocks read-only users from modifying resources' do
      post '/api/v1/resources',
           headers: auth_headers(read_only_user),
           params: { resource: { name: 'Blocked' } }

      expect(response).to have_http_status(:forbidden)
      expect(json.dig('error', 'message')).to eq('Only account owners can do that.')
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
          duration_minutes: 45,
          service_ids: [service.id],
        },
      }

      expect(response).to have_http_status(:created)
      expect(json['client_id']).to eq(client.id)
      expect(json['services']).to be_an(Array)
      expect(json['services'].first['title']).to eq(service.title)
    end

    it 'creates an appointment with notes' do
      post '/api/v1/appointments',
           headers: auth_headers(owner),
           params: {
             appointment: {
               client_id: client.id,
               resource_id: resource.id,
               scheduled_at: 4.days.from_now.iso8601,
               status: 'scheduled',
               duration_minutes: 45,
               service_ids: [service.id],
               notes: 'Client requested extra time for consultation.',
             },
           }

      expect(response).to have_http_status(:created)
      expect(json['notes']).to eq('Client requested extra time for consultation.')

      created_appointment = Appointment.find(json['id'])
      expect(created_appointment.notes).to eq('Client requested extra time for consultation.')
    end

    it 'updates and clears appointment notes' do
      patch "/api/v1/appointments/#{appointment.id}",
            headers: auth_headers(owner),
            params: {
              appointment: {
                notes: 'Discussed follow-up services.',
              },
            }

      expect(response).to have_http_status(:ok)
      expect(json['notes']).to eq('Discussed follow-up services.')
      expect(appointment.reload.notes).to eq('Discussed follow-up services.')

      get "/api/v1/appointments/#{appointment.id}",
          headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json['notes']).to eq('Discussed follow-up services.')

      patch "/api/v1/appointments/#{appointment.id}",
            headers: auth_headers(owner),
            params: {
              appointment: {
                notes: '',
              },
            }

      expect(response).to have_http_status(:ok)
      expect(json['notes']).to eq('')
      expect(appointment.reload.notes).to eq('')
    end

    it 'returns the booked price even after the provider changes their price' do
      offering = UserService.find_by!(
        user: owner,
        service: service
      )

      offering.update!(price: 95)

      post '/api/v1/appointments', headers: auth_headers(owner), params: {
        appointment: {
          client_id: client.id,
          resource_id: resource.id,
          scheduled_at: 7.days.from_now.iso8601,
          status: 'scheduled',
          duration_minutes: 45,
          service_ids: [service.id],
        },
      }

      expect(response).to have_http_status(:created)

      appointment_id = json['id']
      Appointment.find(appointment_id)

      expect(json['services'].first['price'].to_d).to eq(95)
      offering.update!(price: 120)

      get "/api/v1/appointments/#{appointment_id}",
          headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json['services'].first['price'].to_d).to eq(95)
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
          duration_minutes: 45,
          service_ids: [service.id],
        },
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig('error', 'details', 'resource')).to include('is already booked at the scheduled time')
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
      expect(json.dig('error', 'message')).to eq('Only account owners can do that.')
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

  it 'archives a service without deleting it' do
    delete "/api/v1/services/#{service.id}", headers: auth_headers(owner)

    expect(response).to have_http_status(:no_content)

    service.reload
    expect(service.archived?).to be true
    expect(Service.exists?(service.id)).to be true

    get '/api/v1/services', headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(json.pluck('id')).not_to include(service.id)
  end

  it 'restores an archived service' do
    service.archive!

    patch "/api/v1/services/#{service.id}/restore",
          headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)

    service.reload
    expect(service.archived?).to be false

    get '/api/v1/services', headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(json.pluck('id')).to include(service.id)
  end

  it 'lists archived services separately from active services' do
    service.archive!

    get '/api/v1/services/archived', headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(json.pluck('id')).to include(service.id)

    get '/api/v1/services', headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(json.pluck('id')).not_to include(service.id)
  end
end
