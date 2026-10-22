require 'rails_helper'

RSpec.describe 'Api::V1::Appointments', type: :request do
  describe 'GET /api/v1/appointments' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:headers) { auth_headers(user) }

    it 'returns appointments in chronological order' do
      later = create(
        :appointment,
        account: account,
        user: user,
        scheduled_at: 5.days.from_now
      )

      earlier = create(
        :appointment,
        account: account,
        user: user,
        scheduled_at: 2.days.from_now
      )

      middle = create(
        :appointment,
        account: account,
        user: user,
        scheduled_at: 3.days.from_now
      )

      get '/api/v1/appointments', headers: headers

      expect(response).to have_http_status(:ok)

      appointment_ids = response.parsed_body.pluck('id')

      expect(appointment_ids).to eq([
                                      earlier.id,
                                      middle.id,
                                      later.id,
                                    ])
    end
  end
end
