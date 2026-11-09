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

  describe 'PATCH /api/v1/users/:id/activate' do
    let(:account) { create(:account) }
    let(:owner) { create(:user, account: account, role: 'owner') }
    let(:staff) { create(:user, account: account, role: 'staff', active: false) }
    let(:headers) { auth_headers(owner) }

    def activate_user(user, request_headers = headers)
      patch "/api/v1/users/#{user.id}/activate",
            headers: request_headers
    end

    it 'allows an owner to reactivate deactivated staff' do
      activate_user(staff)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['active']).to be true
      expect(staff.reload).to be_active
    end

    it 'does not allow staff to reactivate another user' do
      active_staff = create(:user, account: account, role: 'staff')

      activate_user(staff, auth_headers(active_staff))

      expect(response).to have_http_status(:forbidden)
      expect(staff.reload).not_to be_active
    end

    it 'does not allow read-only users to reactivate another user' do
      read_only_user = create(:user, account: account, role: 'read_only')

      activate_user(staff, auth_headers(read_only_user))

      expect(response).to have_http_status(:forbidden)
      expect(staff.reload).not_to be_active
    end

    it 'does not allow an owner to reactivate users from another account' do
      other_account = create(:account)
      other_staff = create(
        :user,
        account: other_account,
        role: 'staff',
        active: false
      )

      activate_user(other_staff)

      expect(response).to have_http_status(:not_found)
      expect(other_staff.reload).not_to be_active
    end

    it 'preserves the users existing role when reactivated' do
      activate_user(staff)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['role']).to eq('staff')
      expect(staff.reload.role).to eq('staff')
    end

    it 'restores access using an existing JWT after reactivation' do
    staff.update!(active: true)
    staff_headers = auth_headers(staff)

    staff.update!(active: false)

    get '/api/v1/me', headers: staff_headers

    expect(response).to have_http_status(:unauthorized)

    activate_user(staff)

    expect(response).to have_http_status(:ok)

    get '/api/v1/me', headers: staff_headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['id']).to eq(staff.id)
  end
  end

  describe 'PATCH /api/v1/users/:id (avatar)' do
    let(:account) { create(:account) }
    let(:staff) { create(:user, account: account, role: 'staff') }
    let(:headers) { auth_headers(staff) }

    def upload_file(content:, filename:, content_type:)
      Rack::Test::UploadedFile.new(
        StringIO.new(content),
        content_type,
        original_filename: filename
      )
    end

    def update_avatar(user, file, request_headers = headers)
      patch "/api/v1/users/#{user.id}",
            params: { user: { avatar: file } },
            headers: request_headers
    end

    it 'allows a user to upload their own avatar' do
      file = upload_file(
        content: 'test image content',
        filename: 'avatar.png',
        content_type: 'image/png'
      )

      update_avatar(staff, file)

      expect(response).to have_http_status(:ok)
      expect(staff.reload.avatar).to be_attached
      expect(response.parsed_body['avatar_url']).to be_present
    end

    it 'replaces the existing avatar' do
      first_file = upload_file(
        content: 'first image',
        filename: 'first.png',
        content_type: 'image/png'
      )

      update_avatar(staff, first_file)

      expect(response).to have_http_status(:ok)

      first_blob_id = staff.reload.avatar.blob.id

      second_file = upload_file(
        content: 'second image',
        filename: 'second.png',
        content_type: 'image/png'
      )

      update_avatar(staff, second_file)

      expect(response).to have_http_status(:ok)
      expect(staff.reload.avatar.blob.id).not_to eq(first_blob_id)
    end

    it 'returns nil when the user has no avatar' do
      get '/api/v1/me', headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['avatar_url']).to be_nil
    end

    it 'rejects unsupported file types' do
      file = upload_file(
        content: 'not an image',
        filename: 'document.txt',
        content_type: 'text/plain'
      )

      update_avatar(staff, file)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(staff.reload.avatar).not_to be_attached
    end

    it 'rejects files larger than 5 MB' do
      file = upload_file(
        content: 'a' * (5.megabytes + 1),
        filename: 'large.png',
        content_type: 'image/png'
      )

      update_avatar(staff, file)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(staff.reload.avatar).not_to be_attached
    end

    it 'prevents staff from updating another users avatar' do
      other_staff = create(:user, account: account, role: 'staff')

      file = upload_file(
        content: 'test image',
        filename: 'avatar.png',
        content_type: 'image/png'
      )

      update_avatar(other_staff, file)

      expect(response).to have_http_status(:forbidden)
      expect(other_staff.reload.avatar).not_to be_attached
    end
  end
end
