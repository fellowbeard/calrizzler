require 'rails_helper'

RSpec.describe AppointmentService, type: :model do
  let(:account) { create(:account) }
  let(:provider) { create(:user, account: account) }
  let(:service) { create(:service, account: account) }

  let!(:offering) do
    create(:user_service, user: provider, service: service, price: 95)
  end

  let(:appointment) do
    build(:appointment,
          account: account,
          user: provider,
          services: [service])
  end

  it 'captures the provider price when the appointment is booked' do
    appointment.save!

    appointment_service = appointment.appointment_services.first

    expect(appointment_service.price_at_booking).to eq(95)
  end

  it 'preserves the booked price when the provider changes their price' do
    appointment.save!

    appointment_service = appointment.appointment_services.first

    offering.update!(price: 120)

    expect(appointment_service.reload.price_at_booking).to eq(95)
  end

  it 'rejects a service the provider does not offer' do
    other_service = create(:service, account: account)

    appointment.save!

    appointment_service = described_class.new(
      appointment: appointment,
      service: other_service
    )

    expect(appointment_service).not_to be_valid
    expect(appointment_service.errors[:service])
      .to include('is not offered by this provider')
  end

  it 'captures different prices for different providers' do
    other_provider = create(:user, account: account)

    create(:user_service,
           user: other_provider,
           service: service,
           price: 110)

    appointment.save!

    other_appointment = build(:appointment,
                              account: account,
                              user: other_provider,
                              services: [service])

    other_appointment.save!

    expect(appointment.appointment_services.first.price_at_booking).to eq(95)
    expect(other_appointment.appointment_services.first.price_at_booking).to eq(110)
  end

  it 'preserves existing prices when adding another service' do
    appointment.save!

    offering.update!(price: 120)

    new_service = create(:service, account: account)

    create(
      :user_service,
      user: provider,
      service: new_service,
      price: 60
    )

    appointment.services = [service, new_service]
    appointment.save!

    prices = appointment.appointment_services
                        .reload
                        .pluck(:service_id, :price_at_booking)
                        .to_h

    expect(prices[service.id]).to eq(95)
    expect(prices[new_service.id]).to eq(60)
  end

  it 'removes a service without changing the remaining booked price' do
    second_service = create(:service, account: account)

    create(
      :user_service,
      user: provider,
      service: second_service,
      price: 60
    )

    appointment.services = [service, second_service]
    appointment.save!

    offering.update!(price: 120)

    appointment.services = [service]
    appointment.save!

    remaining = appointment.appointment_services.reload

    expect(remaining.count).to eq(1)
    expect(remaining.first.service_id).to eq(service.id)
    expect(remaining.first.price_at_booking).to eq(95)
  end
end
