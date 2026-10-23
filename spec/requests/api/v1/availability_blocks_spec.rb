require 'rails_helper'

RSpec.describe 'Api::V1::AvailabilityBlocks', type: :request do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account, role: 'owner') }
  let(:staff) { create(:user, account: account, role: 'staff') }
  let(:other_staff) { create(:user, account: account, role: 'staff') }
  let(:read_only) { create(:user, account: account, role: 'read_only') }

  let(:valid_params) do
    {
      availability_block: {
        starts_at: '2026-11-02T13:00:00Z',
        ends_at: '2026-11-02T15:00:00Z',
      },
    }
  end

  def create_block(user)
    AvailabilityBlock.create!(
      user: user,
      account: user.account,
      starts_at: Time.zone.parse('2026-11-02 13:00'),
      ends_at: Time.zone.parse('2026-11-02 15:00')
    )
  end

  describe 'GET /api/v1/availability_blocks' do
    it 'allows staff to view their own blocks' do
      create_block(staff)
      
      get '/api/v1/availability_blocks',
      headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end

    it 'allows read-only users to view provider blocks' do
      create_block(staff)

      get '/api/v1/availability_blocks',
          params: { user_id: staff.id },
          headers: auth_headers(read_only)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(1)
    end

    it 'does not expose blocks from another account' do
      outside_user = create(:user, account: create(:account))
      create_block(outside_user)

      get '/api/v1/availability_blocks',
          params: { user_id: outside_user.id },
          headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/availability_blocks' do
    it 'allows staff to create their own block' do
      post '/api/v1/availability_blocks',
           params: valid_params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:created)
      expect(staff.availability_blocks.count).to eq(1)
    end

    it 'prevents staff from blocking another provider' do
      post '/api/v1/availability_blocks',
           params: valid_params.merge(user_id: other_staff.id),
           headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
      expect(other_staff.availability_blocks.count).to eq(0)
    end

    it 'allows owners to block time for staff' do
      post '/api/v1/availability_blocks',
           params: valid_params.merge(user_id: staff.id),
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(staff.availability_blocks.count).to eq(1)
    end

    it 'allows owners to create business-wide closures' do
      post '/api/v1/availability_blocks',
           params: valid_params.merge(scope: 'account'),
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)

      block = AvailabilityBlock.last
      expect(block.account).to eq(account)
      expect(block.user).to be_nil
    end

    it 'prevents read-only users from creating blocks' do
      post '/api/v1/availability_blocks',
           params: valid_params,
           headers: auth_headers(read_only)

      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects a block with invalid times' do
      invalid_params = {
        availability_block: {
          starts_at: '2026-11-02T15:00:00Z',
          ends_at: '2026-11-02T13:00:00Z',
        },
      }

      post '/api/v1/availability_blocks',
           params: invalid_params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/availability_blocks/:id' do
    it 'allows staff to update their own block' do
      block = create_block(staff)

      patch "/api/v1/availability_blocks/#{block.id}",
            params: {
              availability_block: {
                ends_at: '2026-11-02T18:00:00Z',
              },
            },
            headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(block.reload.ends_at.utc.hour).to eq(18)
    end

    it 'prevents staff from updating another provider block' do
      block = create_block(other_staff)

      patch "/api/v1/availability_blocks/#{block.id}",
            params: {
              availability_block: {
                ends_at: '2026-11-02T18:00:00Z',
              },
            },
            headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/availability_blocks/:id' do
    it 'allows staff to delete their own block' do
      block = create_block(staff)

      delete "/api/v1/availability_blocks/#{block.id}",
             headers: auth_headers(staff)

      expect(response).to have_http_status(:no_content)
      expect(AvailabilityBlock.exists?(block.id)).to be(false)
    end

    it 'prevents staff from deleting another provider block' do
      block = create_block(other_staff)

      delete "/api/v1/availability_blocks/#{block.id}",
             headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
      expect(AvailabilityBlock.exists?(block.id)).to be(true)
    end
  end
end
