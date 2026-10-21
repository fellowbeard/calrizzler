require 'rails_helper'

RSpec.describe 'Rack::Attack rate limiting', type: :request do
  describe 'POST /api/v1/login' do
    let(:ip_address) { '203.0.113.10' }

    around do |example|
      original_enabled = Rack::Attack.enabled
      original_cache = Rack::Attack.cache.store

      begin
        Rack::Attack.enabled = true
        Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

        example.run
      ensure
        Rack::Attack.enabled = original_enabled
        Rack::Attack.cache.store = original_cache
      end
    end

    it 'returns 429 after five login attempts from the same IP' do
      headers = { 'REMOTE_ADDR' => ip_address }

      5.times do
        post '/api/v1/login',
             params: {
               email: 'nonexistent@example.com',
               password: 'incorrect',
             },
             headers: headers

        expect(response).not_to have_http_status(:too_many_requests)
      end

      post '/api/v1/login',
           params: {
             email: 'nonexistent@example.com',
             password: 'incorrect',
           },
           headers: headers

      expect(response).to have_http_status(:too_many_requests)

      body = JSON.parse(response.body)

      expect(body['error']).to eq('too_many_requests')
      expect(response.headers['Retry-After']).to be_present
    end
  end
end
