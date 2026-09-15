require 'rails_helper'

RSpec.describe 'Password Resets API', type: :request do
  let!(:account) do
    Account.create!(
      business_name: 'Test Business'
    )
  end

  let!(:user) do
    User.create!(
      account: account,
      email: 'user@example.com',
      password: 'old-password',
      password_confirmation: 'old-password',
      role: 'owner'
    )
  end

  describe 'POST /api/v1/password_resets' do
    it 'creates a password reset for an existing user' do
      expect do
        post '/api/v1/password_resets',
             params: { email: user.email }
      end.to change(PasswordReset, :count).by(1)

      expect(response).to have_http_status(:ok)

      reset = PasswordReset.last

      expect(reset.user).to eq(user)
      expect(reset.expires_at).to be > Time.current
      expect(reset.used_at).to be_nil
    end

    it 'does not reveal whether an email belongs to an account' do
      post '/api/v1/password_resets',
           params: { email: user.email }

      existing_response = response.parsed_body

      expect(response).to have_http_status(:ok)

      expect do
        post '/api/v1/password_resets',
             params: { email: 'does-not-exist@example.com' }
      end.not_to change(PasswordReset, :count)

      unknown_response = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(existing_response).to eq(unknown_response)
    end

    it 'does not store the raw reset token' do
      token_data = {
        token: 'raw-secret-token',
        digest: SecureToken.digest('raw-secret-token'),
      }

      allow(SecureToken).to receive(:generate).and_return(token_data)

      post '/api/v1/password_resets',
           params: { email: user.email }

      reset = PasswordReset.last

      expect(reset.token_digest).to eq(token_data[:digest])
      expect(reset.token_digest).not_to eq(token_data[:token])
    end
  end

  describe 'POST /api/v1/password_resets/confirm' do
    def create_reset_for(user, expires_at: 1.hour.from_now, used_at: nil)
      token_data = SecureToken.generate

      reset = user.password_resets.create!(
        token_digest: token_data[:digest],
        expires_at: expires_at,
        used_at: used_at
      )

      [reset, token_data[:token]]
    end

    it 'changes the password and consumes the token when valid' do
      reset, token = create_reset_for(user)

      post '/api/v1/password_resets/confirm',
           params: {
             token: token,
             password: 'new-password',
             password_confirmation: 'new-password',
           }

      expect(response).to have_http_status(:ok)

      user.reload
      reset.reload

      expect(user.authenticate('new-password')).to eq(user)
      expect(user.authenticate('old-password')).to be_falsey
      expect(reset.used_at).to be_present
      expect(reset.usable?).to be(false)
    end

    it 'rejects an expired token' do
      _reset, token = create_reset_for(
        user,
        expires_at: 1.minute.ago
      )

      post '/api/v1/password_resets/confirm',
           params: {
             token: token,
             password: 'new-password',
             password_confirmation: 'new-password',
           }

      expect(response).to have_http_status(:unprocessable_entity)

      expect(user.reload.authenticate('old-password')).to eq(user)
    end

    it 'rejects an already-used token' do
      _reset, token = create_reset_for(
        user,
        used_at: 1.minute.ago
      )

      post '/api/v1/password_resets/confirm',
           params: {
             token: token,
             password: 'new-password',
             password_confirmation: 'new-password',
           }

      expect(response).to have_http_status(:unprocessable_entity)

      expect(user.reload.authenticate('old-password')).to eq(user)
    end

    it 'rejects an invalid token' do
      post '/api/v1/password_resets/confirm',
           params: {
             token: 'definitely-not-a-real-token',
             password: 'new-password',
             password_confirmation: 'new-password',
           }

      expect(response).to have_http_status(:unprocessable_entity)

      expect(user.reload.authenticate('old-password')).to eq(user)
    end

    it 'does not consume the token when password validation fails' do
      reset, token = create_reset_for(user)

      post '/api/v1/password_resets/confirm',
           params: {
             token: token,
             password: 'new-password',
             password_confirmation: 'different-password',
           }

      expect(response).to have_http_status(:unprocessable_entity)

      expect(user.reload.authenticate('old-password')).to eq(user)
      expect(reset.reload.used_at).to be_nil
      expect(reset.usable?).to be(true)
    end

    it 'invalidates all outstanding reset tokens after a successful reset' do
      first_reset, first_token = create_reset_for(user)
      second_reset, = create_reset_for(user)

      post '/api/v1/password_resets/confirm',
           params: {
             token: first_token,
             password: 'new-password',
             password_confirmation: 'new-password',
           }

      expect(response).to have_http_status(:ok)

      first_reset.reload
      second_reset.reload

      expect(first_reset.used_at).to be_present
      expect(second_reset.used_at).to be_present
      expect(first_reset.usable?).to be(false)
      expect(second_reset.usable?).to be(false)
    end
  end
end