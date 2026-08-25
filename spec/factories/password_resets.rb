FactoryBot.define do
  factory :password_reset do
    user { nil }
    token_digest { 'MyString' }
    expires_at { '2026-08-24 14:01:36' }
    used_at { '2026-08-24 14:01:36' }
  end
end
