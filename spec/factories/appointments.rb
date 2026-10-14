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
      selected_services =
        if evaluator.services.any?
          evaluator.services
        else
          [build(:service, account: appointment.account)]
        end

      selected_services.each do |service|
        service.save! unless service.persisted?
        appointment.user.save! unless appointment.user.persisted?

        UserService.find_or_create_by!(
          user: appointment.user,
          service: service
        ) do |offering|
          offering.price = service.price
        end
      end

      appointment.services = selected_services
    end
  end
end
