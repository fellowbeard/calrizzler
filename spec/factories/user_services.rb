FactoryBot.define do
  factory :user_service do
    association :user
    service { association(:service, account: user.account) }
    price { 50.00 }
  end
end
