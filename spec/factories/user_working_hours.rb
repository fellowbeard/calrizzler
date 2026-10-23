FactoryBot.define do
  factory :user_working_hour do
    association :user
    day_of_week { 1 }
    opens_at { '09:00' }
    closes_at { '17:00' }
    is_closed { false }
  end
end
