require 'rails_helper'

RSpec.describe 'API V1 Availability', type: :request do
  let(:account) { create(:account, timezone: 'America/Chicago') }
  let(:user) { create(:user, account: account) }
  let(:resource) { create(:resource, account: account) }
  let(:date) { Date.current + 7.days }

  # Replace this with the authentication helper used
  # by your existing request specs.
  let(:headers) { auth_headers(user) }

  before do
    create(
      :working_hour,
      account: account,
      day_of_week: date.wday,
      opens_at: '09:00',
      closes_at: '17:00'
    )
  end

  describe 'GET /api/v1/availability' do
    let(:path) { '/api/v1/availability' }

    it 'returns available appointment slots' do
      get path,
          params: {
            date: date.iso8601,
            duration_minutes: 60,
            resource_id: resource.id,
          },
          headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body['date']).to eq(date.iso8601)
      expect(body['timezone']).to eq('America/Chicago')
      expect(body['slots']).to be_an(Array)
      expect(body['slots'].length).to eq(29)
    end

    it 'excludes slots that overlap an existing appointment' do
      appointment_start = Time.find_zone!('America/Chicago')
                              .local(date.year, date.month, date.day, 10, 0)

      create(
        :appointment,
        account: account,
        user: user,
        resource: resource,
        scheduled_at: appointment_start,
        duration_minutes: 60,
        status: 'scheduled'
      )

      get path,
          params: {
            date: date.iso8601,
            duration_minutes: 60,
            resource_id: resource.id,
          },
          headers: headers

      expect(response).to have_http_status(:ok)

      slots = response.parsed_body['slots']

      expect(slots).not_to include(
        appointment_start.utc.iso8601
      )

      expect(slots).not_to include(
        (appointment_start - 15.minutes).utc.iso8601
      )

      expect(slots).not_to include(
        (appointment_start - 30.minutes).utc.iso8601
      )

      expect(slots).not_to include(
        (appointment_start - 45.minutes).utc.iso8601
      )

      expect(slots).to include(
        (appointment_start + 60.minutes).utc.iso8601
      )
    end

    it 'rejects a missing date' do
      get path,
          params: {
            duration_minutes: 60,
            resource_id: resource.id,
          },
          headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('error', 'code'))
        .to eq('invalid_availability_parameters')
    end

    it 'rejects a zero duration' do
      get path,
          params: {
            date: date.iso8601,
            duration_minutes: 0,
            resource_id: resource.id,
          },
          headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'does not expose resources belonging to another account' do
      other_account = create(:account)
      other_resource = create(:resource, account: other_account)

      get path,
          params: {
            date: date.iso8601,
            duration_minutes: 60,
            resource_id: other_resource.id,
          },
          headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
