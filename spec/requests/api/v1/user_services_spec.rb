require 'rails_helper'

RSpec.describe 'Api::V1::UserServices', type: :request do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account, role: 'owner') }
  let(:staff) { create(:user, account: account, role: 'staff') }
  let(:other_staff) { create(:user, account: account, role: 'staff') }
  let(:read_only) { create(:user, account: account, role: 'read_only') }

  let(:service) { create(:service, account: account) }

  describe 'POST /api/v1/users/:user_id/user_services' do
    let(:params) do
      {
        user_service: {
          service_id: service.id,
          price: 75.00,
        },
      }
    end

    it 'allows an owner to assign a service to any provider' do
      post "/api/v1/users/#{staff.id}/user_services",
           params: params,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)

      offering = UserService.find_by(user: staff, service: service)

      expect(offering).to be_present
      expect(offering.price).to eq(75)
    end

    it 'allows staff to assign a service to themselves' do
      post "/api/v1/users/#{staff.id}/user_services",
           params: params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:created)

      expect(UserService.exists?(user: staff, service: service)).to be true
    end

    it 'prevents staff from assigning services to another provider' do
      post "/api/v1/users/#{other_staff.id}/user_services",
           params: params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
      expect(UserService.exists?(user: other_staff, service: service)).to be false
    end

    it 'prevents read-only users from assigning services' do
      post "/api/v1/users/#{read_only.id}/user_services",
           params: params,
           headers: auth_headers(read_only)

      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents assigning a service from another account' do
      other_account = create(:account)
      foreign_service = create(:service, account: other_account)

      post "/api/v1/users/#{staff.id}/user_services",
           params: {
             user_service: {
               service_id: foreign_service.id,
               price: 75,
             },
           },
           headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
      expect(UserService.exists?(user: staff, service: foreign_service)).to be false
    end

    it 'prevents accessing a provider from another account' do
      other_account = create(:account)
      foreign_staff = create(:user, account: other_account, role: 'staff')

      post "/api/v1/users/#{foreign_staff.id}/user_services",
           params: params,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end

    it 'prevents duplicate provider-service assignments' do
      create(:user_service, user: staff, service: service)

      post "/api/v1/users/#{staff.id}/user_services",
           params: params,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(UserService.where(user: staff, service: service).count).to eq(1)
    end
  end

  describe 'PATCH /api/v1/users/:user_id/user_services/:id' do
    let(:offering) do
      create(:user_service, user: staff, service: service, price: 50)
    end

    it 'allows an owner to update another providers price' do
      patch "/api/v1/users/#{staff.id}/user_services/#{offering.id}",
            params: { user_service: { price: 85 } },
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(offering.reload.price).to eq(85)
    end

    it 'allows staff to update their own price' do
      patch "/api/v1/users/#{staff.id}/user_services/#{offering.id}",
            params: { user_service: { price: 65 } },
            headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(offering.reload.price).to eq(65)
    end

    it 'prevents staff from updating another providers price' do
      patch "/api/v1/users/#{staff.id}/user_services/#{offering.id}",
            params: { user_service: { price: 1 } },
            headers: auth_headers(other_staff)

      expect(response).to have_http_status(:forbidden)
      expect(offering.reload.price).to eq(50)
    end

    it 'prevents read-only users from updating prices' do
      patch "/api/v1/users/#{staff.id}/user_services/#{offering.id}",
            params: { user_service: { price: 1 } },
            headers: auth_headers(read_only)

      expect(response).to have_http_status(:forbidden)
      expect(offering.reload.price).to eq(50)
    end

    it 'rejects negative prices' do
      patch "/api/v1/users/#{staff.id}/user_services/#{offering.id}",
            params: { user_service: { price: -10 } },
            headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(offering.reload.price).to eq(50)
    end
  end

  describe 'DELETE /api/v1/users/:user_id/user_services/:id' do
    let!(:offering) do
      create(:user_service, user: staff, service: service, price: 50)
    end

    it 'allows staff to remove their own offering' do
      delete "/api/v1/users/#{staff.id}/user_services/#{offering.id}",
             headers: auth_headers(staff)

      expect(response).to have_http_status(:no_content)
      expect(UserService.exists?(offering.id)).to be false
    end

    it 'prevents staff from removing another providers offering' do
      delete "/api/v1/users/#{staff.id}/user_services/#{offering.id}",
             headers: auth_headers(other_staff)

      expect(response).to have_http_status(:forbidden)
      expect(UserService.exists?(offering.id)).to be true
    end
  end

  describe 'GET /api/v1/users/:user_id/user_services' do
    it 'returns a providers services and prices' do
      offering = create(
        :user_service,
        user: staff,
        service: service,
        price: 75
      )

      get "/api/v1/users/#{staff.id}/user_services",
          headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body.length).to eq(1)
      expect(body.first['id']).to eq(offering.id)
      expect(body.first['service_id']).to eq(service.id)
      expect(body.first['price'].to_d).to eq(75)
    end
    it 'prevents viewing offerings from another account' do
      other_account = create(:account)
      foreign_provider = create(:user, account: other_account, role: 'staff')
      foreign_service = create(:service, account: other_account)

      create(
        :user_service,
        user: foreign_provider,
        service: foreign_service,
        price: 150
      )

      get "/api/v1/users/#{foreign_provider.id}/user_services",
          headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end
  end
end
