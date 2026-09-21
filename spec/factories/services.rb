FactoryBot.define do
  factory :service do
    association :account
    sequence(:title) { |n| "Service #{n}" }
    price { 100.0 }
    duration_minutes { 45 }
    description { 'Basic service' }
  end
end
