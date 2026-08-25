FactoryBot.define do
  factory :user_invitation do
    account { nil }
    invited_by { nil }
    email { 'MyString' }
    role { 'MyString' }
    token_digest { 'MyString' }
    expires_at { '2026-08-24 14:01:25' }
    accepted_at { '2026-08-24 14:01:25' }
  end
end
