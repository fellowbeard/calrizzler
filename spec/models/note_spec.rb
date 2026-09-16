require 'rails_helper'

RSpec.describe Note, type: :model do
  let(:account) { Account.create!(business_name: 'Acme') }
  let(:user) do
    account.users.create!(first_name: 'Jane', last_name: 'Doe', email: 'jane@example.com', role: 'owner',
                          password: 'password', password_confirmation: 'password')
  end
  let(:client) do
    account.clients.create!(first_name: 'John', last_name: 'Client', email: 'john@example.com', user: user)
  end

  it 'requires a body' do
    note = client.notes.new(user: user)

    expect(note).not_to be_valid
    expect(note.errors[:body]).to include("can't be blank")
  end

  it 'requires a user' do
    note = client.notes.new(body: 'Test note')

    expect(note).not_to be_valid
    expect(note.errors[:user]).to include("must exist")
  end

  it 'requires a client' do
    note = Note.new(body: 'Test note', user: user)

    expect(note).not_to be_valid
    expect(note.errors[:client]).to include("must exist")
  end

  it 'creates a valid note with all required attributes' do
    note = client.notes.new(body: 'This is a test note', user: user)

    expect(note).to be_valid
    expect(note.save).to be true
  end

  it 'belongs to a user' do
    note = client.notes.create!(body: 'Test note', user: user)

    expect(note.user).to eq(user)
  end

  it 'belongs to a client' do
    note = client.notes.create!(body: 'Test note', user: user)

    expect(note.client).to eq(client)
  end

  it 'is destroyed when the client is destroyed' do
    note = client.notes.create!(body: 'Test note', user: user)
    note_id = note.id

    client.destroy

    expect(Note.find_by(id: note_id)).to be_nil
  end

  it 'can store notes with multiple lines and special characters' do
    multiline_body = "This is a multiline note\nWith special chars: !@#$%^&*()\nAnd emoji: 😀"
    note = client.notes.create!(body: multiline_body, user: user)

    expect(note.reload.body).to eq(multiline_body)
  end
end
