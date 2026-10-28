require 'rails_helper'

RSpec.describe 'Api::V1::UserWorkingHours', type: :request do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account, role: 'owner') }
  let(:staff) { create(:user, account: account, role: 'staff') }
  let(:other_staff) { create(:user, account: account, role: 'staff') }
  let(:read_only) { create(:user, account: account, role: 'read_only') }

  let(:valid_params) do
    {
      user_working_hour: {
        day_of_week: 1,
        opens_at: '18:00',
        closes_at: '22:00',
      },
    }
  end

  describe 'GET /api/v1/user_working_hours' do
    it 'allows staff to view their own hours' do
      create(:user_working_hour, user: staff)

      get '/api/v1/user_working_hours', headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end

    it 'allows read-only users to view provider hours' do
      create(:user_working_hour, user: staff)

      get '/api/v1/user_working_hours',
          params: { user_id: staff.id },
          headers: auth_headers(read_only)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end
  end

  describe 'POST /api/v1/user_working_hours' do
    it 'allows staff to create their own hours outside business hours' do
      post '/api/v1/user_working_hours',
           params: valid_params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:created)
      expect(staff.user_working_hours.count).to eq(1)
    end

    it 'prevents staff from modifying another provider schedule' do
      post '/api/v1/user_working_hours',
           params: valid_params.merge(user_id: other_staff.id),
           headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
      expect(other_staff.user_working_hours.count).to eq(0)
    end

    it 'allows owners to create hours for staff' do
      post '/api/v1/user_working_hours',
           params: valid_params.merge(user_id: staff.id),
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(staff.user_working_hours.count).to eq(1)
    end

    it 'prevents read-only users from creating hours' do
      post '/api/v1/user_working_hours',
           params: valid_params,
           headers: auth_headers(read_only)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /api/v1/user_working_hours/:id' do
    it 'allows staff to update their own hours' do
      hour = create(:user_working_hour, user: staff)

      patch "/api/v1/user_working_hours/#{hour.id}",
            params: { user_working_hour: { closes_at: '20:00' } },
            headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(hour.reload.closes_at.strftime('%H:%M')).to eq('20:00')
    end

    it 'prevents staff from updating another provider hours' do
      hour = create(:user_working_hour, user: other_staff)

      patch "/api/v1/user_working_hours/#{hour.id}",
            params: { user_working_hour: { closes_at: '20:00' } },
            headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/user_working_hours/:id' do
    it 'allows staff to delete their own hours' do
      hour = create(:user_working_hour, user: staff)

      delete "/api/v1/user_working_hours/#{hour.id}",
             headers: auth_headers(staff)

      expect(response).to have_http_status(:no_content)
      expect(UserWorkingHour.exists?(hour.id)).to be(false)
    end

    it 'prevents staff from deleting another provider hours' do
      hour = create(:user_working_hour, user: other_staff)

      delete "/api/v1/user_working_hours/#{hour.id}",
             headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
      expect(UserWorkingHour.exists?(hour.id)).to be(true)
    end
  end
end
