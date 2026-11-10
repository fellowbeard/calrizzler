require 'rails_helper'

RSpec.describe 'Api::V1::Search', type: :request do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account) }
  let(:staff) { create(:user, :staff, account: account) }

  let!(:client) do
    create(
      :client,
      account: account,
      user: owner,
      first_name: 'Jane',
      last_name: 'Smith',
      email: 'jane@example.com',
      phone: '5045551234'
    )
  end

  let!(:service) do
    create(
      :service,
      account: account,
      title: 'Deep Tissue Massage'
    )
  end

  let!(:appointment) do
    create(
      :appointment,
      account: account,
      user: owner,
      client: client,
      scheduled_at: 3.days.from_now
    )
  end

  describe 'GET /api/v1/search' do
    it 'requires authentication' do
      get '/api/v1/search', params: { q: 'Jane' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns empty results for a blank query' do
      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: ' ' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'clients' => [],
        'appointments' => [],
        'services' => []
      )
    end

    it 'finds clients by full name' do
      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: 'Jane Smith' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['clients'].pluck('id')).to include(client.id)
      expect(response.parsed_body['services']).to be_empty
    end

    it 'finds clients by email' do
      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: 'jane@example.com' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['clients'].pluck('id')).to include(client.id)
    end

    it 'finds appointments by client name' do
      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: 'Jane' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments'].pluck('id')).to include(appointment.id)
    end

    it 'finds active services by title' do
      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: 'tissue' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['services'].pluck('id')).to include(service.id)
    end

    it 'finds appointments by service title' do
      create(
        :user_service,
        user: owner,
        service: service,
        price: service.price
      )

      appointment.services = [service]

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: 'tissue' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments'].pluck('id')).to include(appointment.id)
    end

    it 'does not expose another user clients or appointments' do
      get '/api/v1/search',
          headers: auth_headers(staff),
          params: { q: 'Jane' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['clients']).to be_empty
      expect(response.parsed_body['appointments']).to be_empty
    end

    it 'does not expose another account records' do
      other_account = create(:account)
      other_user = create(:user, account: other_account)

      create(
        :client,
        account: other_account,
        user: other_user,
        first_name: 'Unique',
        last_name: 'Customer'
      )

      create(
        :service,
        account: other_account,
        title: 'Unique Service'
      )

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: 'Unique' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.values.flatten).to be_empty
    end

    it 'limits client results to 20' do
      create_list(
        :client,
        25,
        account: account,
        user: owner,
        first_name: 'Searchable'
      )

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: 'Searchable' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['clients'].length).to eq(20)
    end

    it 'treats SQL wildcard characters as literal search text' do
      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { q: '%' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.values.flatten).to be_empty
    end

    it 'finds appointments by status without a text query' do
      appointment.update!(status: 'canceled')

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { status: 'canceled' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments'].pluck('id')).to include(appointment.id)
      expect(response.parsed_body['clients']).to be_empty
      expect(response.parsed_body['services']).to be_empty
    end

    it 'finds appointments by date without a text query' do
      date = appointment.scheduled_at.in_time_zone(account.timezone).to_date

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { date: date.iso8601 }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments'].pluck('id')).to include(appointment.id)
    end

    it 'combines date and status filters' do
      appointment.update!(status: 'canceled')

      date = appointment.scheduled_at.in_time_zone(account.timezone).to_date

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: {
            date: date.iso8601,
            status: 'scheduled',
          }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments']).to be_empty
    end

    it 'combines text search with status filtering' do
      appointment.update!(status: 'canceled')

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: {
            q: 'Jane',
            status: 'scheduled',
          }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments']).to be_empty
      expect(response.parsed_body['clients']).to be_empty
      expect(response.parsed_body['services']).to be_empty
    end

    it 'respects the account timezone when filtering by date' do
      account.update!(timezone: 'America/Los_Angeles')

      appointment.update!(
        scheduled_at: Time.utc(2026, 11, 16, 7, 30)
      )

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { date: '2026-11-15' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments'].pluck('id')).to include(appointment.id)

      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { date: '2026-11-16' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments'].pluck('id')).not_to include(appointment.id)
    end

    it 'does not expose another users appointments through filters' do
      appointment.update!(status: 'canceled')

      get '/api/v1/search',
          headers: auth_headers(staff),
          params: { status: 'canceled' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['appointments']).to be_empty
    end

    it 'rejects invalid statuses' do
      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { status: 'unknown' }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body.dig('error', 'code')).to eq('bad_request')
    end

    it 'rejects invalid dates' do
      get '/api/v1/search',
          headers: auth_headers(owner),
          params: { date: '2026-02-30' }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body.dig('error', 'code')).to eq('bad_request')
    end
  end
end
