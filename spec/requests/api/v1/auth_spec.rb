require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  let!(:account) { Account.create!(business_name: 'Test Co') }
  let!(:user) do
    account.users.create!(
      first_name: 'Owner',
      last_name: 'User',
      email: 'owner@example.com',
      role: 'owner',
      password: 'password',
      password_confirmation: 'password'
    )
  end

  describe 'POST /api/v1/login' do
    it 'returns a token for valid credentials' do
      post '/api/v1/login', params: { email: user.email, password: 'password' }

      expect(response).to have_http_status(:ok)
      expect(json['token']).to be_present
      expect(json['user']).to include('id' => user.id, 'email' => user.email)
    end

    it 'returns unauthorized for invalid credentials' do
      post '/api/v1/login', params: { email: user.email, password: 'wrong' }

      expect(response).to have_http_status(:unauthorized)
      expect(json['error']).to be_present
      expect(json.dig('error', 'message')).to be_present
    end

    it 'does not issue a token to a deactivated user' do
      user.update!(active: false)

      post '/api/v1/login',
           params: {
             email: user.email,
             password: 'password',
           }

      expect(response).to have_http_status(:forbidden)
      expect(json['token']).to be_nil
      expect(json.dig('error', 'code')).to eq('account_deactivated')
      expect(json.dig('error', 'message')).to eq(
        'Your account has been deactivated. Contact your account owner for access.'
      )
    end

    it 'does not reveal deactivation when the password is incorrect' do
      user.update!(active: false)

      post '/api/v1/login',
           params: {
             email: user.email,
             password: 'wrong',
           }

      expect(response).to have_http_status(:unauthorized)
      expect(json['token']).to be_nil
      expect(json.dig('error', 'code')).to eq('invalid_credentials')
      expect(json.dig('error', 'message')).to eq('Invalid email or password.')
    end
  end
end
