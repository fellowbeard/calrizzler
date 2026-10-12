require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'DELETE /api/v1/users/:id' do
    let(:account) { create(:account) }
    let(:owner) { create(:user, account: account, role: 'owner') }
    let(:staff) { create(:user, account: account, role: 'staff') }
    let(:headers) { auth_headers(owner) }

    it 'deactivates the user instead of deleting them' do
      delete "/api/v1/users/#{staff.id}", headers: headers

      expect(response).to have_http_status(:no_content)

      staff.reload

      expect(staff).not_to be_active
      expect(User.exists?(staff.id)).to be true
    end

    it 'preserves the users appointments' do
      appointment = create(
        :appointment,
        account: account,
        user: staff
      )

      delete "/api/v1/users/#{staff.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(Appointment.exists?(appointment.id)).to be true
      expect(appointment.reload.user_id).to eq(staff.id)
    end

    it 'does not allow an owner to deactivate themselves' do
      delete "/api/v1/users/#{owner.id}", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)

      body = response.parsed_body

      expect(body.dig('error', 'code')).to eq('cannot_deactivate_self')
      expect(owner.reload).to be_active
    end

    it 'does not allow staff to deactivate another user' do
      other_staff = create(:user, account: account, role: 'staff')

      delete "/api/v1/users/#{other_staff.id}",
             headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
      expect(other_staff.reload).to be_active
    end

    it 'invalidates the deactivated users existing JWT' do
      staff_headers = auth_headers(staff)

      delete "/api/v1/users/#{staff.id}", headers: headers

      expect(response).to have_http_status(:no_content)

      get '/api/v1/me', headers: staff_headers

      expect(response).to have_http_status(:unauthorized)

      body = response.parsed_body

      expect(body.dig('error', 'code')).to eq('unauthorized')
    end
  end
end
