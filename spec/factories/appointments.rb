FactoryBot.define do
  factory :appointment do
    association :account

    user do
      association(:user, account: account)
    end

    client do
      association(:client, account: account, user: user)
    end

    resource do
      association(:resource, account: account)
    end

    scheduled_at { 2.days.from_now }
    status { 'scheduled' }
    duration_minutes { 60 }

    transient do
      services { [] }
    end

    after(:build) do |appointment, evaluator|
      if evaluator.services.any?
        appointment.services = evaluator.services
      else
        appointment.services << build(
          :service,
          account: appointment.account
        )
      end
    end
  end
end
