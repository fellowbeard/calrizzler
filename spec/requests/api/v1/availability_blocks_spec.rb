require 'rails_helper'

RSpec.describe 'Api::V1::AvailabilityBlocks', type: :request do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account, role: 'owner') }
  let(:staff) { create(:user, account: account, role: 'staff') }
  let(:other_staff) { create(:user, account: account, role: 'staff') }
  let(:read_only) { create(:user, account: account, role: 'read_only') }

  let(:path) { '/api/v1/availability_blocks' }
  let(:start_time) { Time.utc(2026, 11, 2, 13) }
  let(:end_time) { Time.utc(2026, 11, 2, 15) }
  let(:updated_end_time) { Time.utc(2026, 11, 2, 18) }

  let(:valid_params) do
    {
      availability_block: {
        starts_at: start_time.iso8601,
        ends_at: end_time.iso8601,
      },
    }
  end

  let(:available_params) do
    {
      availability_block: valid_params[:availability_block].merge(
        is_available: true
      ),
    }
  end

  let(:update_params) do
    { availability_block: { ends_at: updated_end_time.iso8601 } }
  end

  def create_block(user: nil, account: nil, is_available: false)
    account ||= user.account

    AvailabilityBlock.create!(
      user: user,
      account: account,
      starts_at: start_time,
      ends_at: end_time,
      is_available: is_available
    )
  end

  describe 'GET /api/v1/availability_blocks' do
    it 'allows users to view provider exceptions' do
      create_block(user: staff)
      create_block(user: staff, is_available: true)

      get path, headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(2)

      get path,
          params: { user_id: staff.id },
          headers: auth_headers(read_only)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it 'allows users to view business-wide closures' do
      create_block(account: account)

      get path,
          params: { scope: 'account' },
          headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end

    it 'isolates provider and business exceptions by account' do
      outside_account = create(:account)
      outside_user = create(:user, account: outside_account)

      create_block(user: outside_user)
      create_block(account: outside_account)

      get path,
          params: { user_id: outside_user.id },
          headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)

      get path,
          params: { scope: 'account' },
          headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_empty
    end

    it 'uses provider scope when user_id and account scope are both given' do
      provider_block = create_block(user: staff)
      create_block(account: account)

      get path,
          params: { scope: 'account', user_id: staff.id },
          headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).map { |block| block['id'] }).to eq(
        [provider_block.id]
      )
    end
  end

  describe 'POST /api/v1/availability_blocks' do
    it 'allows staff and owners to create provider exceptions' do
      post path,
           params: available_params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:created)
      expect(staff.availability_blocks.last.is_available).to be(true)

      post path,
           params: available_params.merge(user_id: other_staff.id),
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(other_staff.availability_blocks.last.is_available).to be(true)
    end

    it 'defaults existing-style blocks to unavailable' do
      post path,
           params: valid_params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:created)
      expect(staff.availability_blocks.last.is_available).to be(false)
    end

    it 'allows only owners to create business-wide closures' do
      post path,
           params: valid_params.merge(scope: 'account'),
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(AvailabilityBlock.last).to have_attributes(
        account: account,
        user: nil,
        is_available: false
      )

      post path,
           params: valid_params.merge(scope: 'account'),
           headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
      expect(account.availability_blocks.where(user_id: nil).count).to eq(1)
    end

    it 'rejects business-wide extra availability' do
      post path,
           params: available_params.merge(scope: 'account'),
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(account.availability_blocks.where(user_id: nil).count).to eq(0)
    end

    it 'enforces provider permissions' do
      post path,
           params: available_params.merge(user_id: other_staff.id),
           headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)

      post path,
           params: available_params,
           headers: auth_headers(read_only)

      expect(response).to have_http_status(:forbidden)
      expect(AvailabilityBlock.count).to eq(0)
    end

    it 'rejects invalid time ranges' do
      invalid_params = {
        availability_block: {
          starts_at: end_time.iso8601,
          ends_at: start_time.iso8601,
          is_available: true,
        },
      }

      post path,
           params: invalid_params,
           headers: auth_headers(staff)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/availability_blocks/:id' do
    it 'allows staff to update their own exceptions' do
      block = create_block(user: staff)

      patch "#{path}/#{block.id}",
            params: {
              availability_block: {
                is_available: true,
                ends_at: updated_end_time.iso8601,
              },
            },
            headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(block.reload).to have_attributes(
        is_available: true,
        ends_at: updated_end_time
      )
    end

    it 'allows owners to update business-wide closures' do
      block = create_block(account: account)

      patch "#{path}/#{block.id}",
            params: update_params,
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(block.reload.ends_at).to eq(updated_end_time)
    end

    it 'prevents converting business-wide closures into extra availability' do
      block = create_block(account: account)

      patch "#{path}/#{block.id}",
            params: { availability_block: { is_available: true } },
            headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(block.reload.is_available).to be(false)
    end

    it 'prevents staff from updating other providers or business closures' do
      [create_block(user: other_staff), create_block(account: account)].each do |block|
        patch "#{path}/#{block.id}",
              params: update_params,
              headers: auth_headers(staff)

        expect(response).to have_http_status(:forbidden)
        expect(block.reload.ends_at).to eq(end_time)
      end
    end
  end

  describe 'DELETE /api/v1/availability_blocks/:id' do
    it 'allows staff to delete their exceptions and owners to delete closures' do
      [
        [create_block(user: staff, is_available: true), staff],
        [create_block(account: account), owner],
      ].each do |block, actor|
        delete "#{path}/#{block.id}", headers: auth_headers(actor)

        expect(response).to have_http_status(:no_content)
        expect(AvailabilityBlock.exists?(block.id)).to be(false)
      end
    end

    it 'prevents staff from deleting other providers or business closures' do
      [create_block(user: other_staff), create_block(account: account)].each do |block|
        delete "#{path}/#{block.id}", headers: auth_headers(staff)

        expect(response).to have_http_status(:forbidden)
        expect(AvailabilityBlock.exists?(block.id)).to be(true)
      end
    end
  end

  describe 'Cross-account protection' do
    it 'prevents updating or deleting another account closure' do
      outside_account = create(:account)
      block = create_block(account: outside_account)

      patch "#{path}/#{block.id}",
            params: update_params,
            headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
      expect(block.reload.ends_at).to eq(end_time)

      delete "#{path}/#{block.id}",
             headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
      expect(AvailabilityBlock.exists?(block.id)).to be(true)
    end
  end
end
