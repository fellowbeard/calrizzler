require 'rails_helper'

RSpec.describe 'Api::V1::WorkingHours', type: :request do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account, role: 'owner') }
  let(:staff) { create(:user, account: account, role: 'staff') }
  let(:read_only) { create(:user, account: account, role: 'read_only') }

  let(:valid_params) do
    {
      working_hour: {
        day_of_week: 1,
        opens_at: '09:00',
        closes_at: '17:00',
      },
    }
  end

  describe 'GET /api/v1/working_hours' do
    it 'allows staff to view business hours' do
      get '/api/v1/working_hours', headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
    end

    it 'allows read-only users to view business hours' do
      get '/api/v1/working_hours', headers: auth_headers(read_only)

      expect(response).to have_http_status(:ok)
    end

    it 'only returns working hours from the current account' do
      own_hours = account.working_hours.create!(
        day_of_week: 1, opens_at: '09:00', closes_at: '17:00'
      )

      other_account = create(:account)
      other_account.working_hours.create!(
        day_of_week: 2, opens_at: '10:00', closes_at: '16:00'
      )

      get '/api/v1/working_hours', headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck('id')).to eq([own_hours.id])
    end
  end

  describe 'POST /api/v1/working_hours' do
    it 'allows owners to create business hours' do
      post '/api/v1/working_hours',
           params: valid_params,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(account.working_hours.count).to eq(1)
    end

    it 'prevents staff from changing business defaults' do
      post '/api/v1/working_hours',
           params: valid_params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents read-only users from creating business hours' do
      post '/api/v1/working_hours',
           params: valid_params,
           headers: auth_headers(read_only)

      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects invalid working hours' do
      post '/api/v1/working_hours',
           params: {
             working_hour: {
               day_of_week: 1,
               opens_at: '17:00',
               closes_at: '09:00',
             },
           },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/working_hours/:id' do
    let!(:hours) do
      account.working_hours.create!(
        day_of_week: 1, opens_at: '09:00', closes_at: '17:00'
      )
    end

    it 'allows owners to update business hours' do
      patch "/api/v1/working_hours/#{hours.id}",
            params: { working_hour: { closes_at: '18:00' } },
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(hours.reload.closes_at.strftime('%H:%M')).to eq('18:00')
    end

    it 'prevents staff from updating business defaults' do
      patch "/api/v1/working_hours/#{hours.id}",
            params: { working_hour: { closes_at: '18:00' } },
            headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents updating another accounts hours' do
      other_account = create(:account)
      foreign_hours = other_account.working_hours.create!(
        day_of_week: 1, opens_at: '09:00', closes_at: '17:00'
      )

      patch "/api/v1/working_hours/#{foreign_hours.id}",
            params: { working_hour: { closes_at: '18:00' } },
            headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/working_hours/:id' do
    let!(:hours) do
      account.working_hours.create!(
        day_of_week: 1, opens_at: '09:00', closes_at: '17:00'
      )
    end

    it 'allows owners to delete business hours' do
      delete "/api/v1/working_hours/#{hours.id}",
             headers: auth_headers(owner)

      expect(response).to have_http_status(:no_content)
      expect(WorkingHour.exists?(hours.id)).to be false
    end

    it 'prevents staff from deleting business defaults' do
      delete "/api/v1/working_hours/#{hours.id}",
             headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents read-only users from deleting business hours' do
      delete "/api/v1/working_hours/#{hours.id}",
             headers: auth_headers(read_only)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT /api/v1/working_hours/replace' do
    let!(:existing) { account.working_hours.create!(day_of_week: 1, opens_at: '09:00', closes_at: '17:00') }

    let(:new_week) do
      {
        working_hours: [
          { day_of_week: 1, opens_at: '08:00', closes_at: '12:00' },
          { day_of_week: 1, opens_at: '13:00', closes_at: '18:00' },
          { day_of_week: 2, opens_at: '10:00', closes_at: '16:00' },
        ],
      }
    end

    it 'replaces the whole schedule for owners' do
      put '/api/v1/working_hours/replace', params: new_week, headers: auth_headers(owner), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |hour| [hour['day_of_week'], hour['opens_at'][11, 5]] })
        .to eq([[1, '08:00'], [1, '13:00'], [2, '10:00']])
      expect(WorkingHour.exists?(existing.id)).to be(false)
    end

    it 'clears the schedule when given an empty list' do
      put '/api/v1/working_hours/replace', params: { working_hours: [] }, headers: auth_headers(owner), as: :json

      expect(response).to have_http_status(:ok)
      expect(account.working_hours.count).to eq(0)
    end

    it 'keeps the old schedule when any range is invalid' do
      overlapping = { day_of_week: 1, opens_at: '11:00', closes_at: '14:00' }
      bad_week = { working_hours: [new_week[:working_hours].first, overlapping] }

      put '/api/v1/working_hours/replace', params: bad_week, headers: auth_headers(owner), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('error', 'code')).to eq('validation_failed')
      expect(account.working_hours.reload.pluck(:id)).to eq([existing.id])
    end

    it 'rejects a request without the working_hours key' do
      put '/api/v1/working_hours/replace', params: {}, headers: auth_headers(owner), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(account.working_hours.count).to eq(1)
    end

    it 'forbids staff' do
      put '/api/v1/working_hours/replace', params: new_week, headers: auth_headers(staff), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(account.working_hours.pluck(:id)).to eq([existing.id])
    end
  end
end
