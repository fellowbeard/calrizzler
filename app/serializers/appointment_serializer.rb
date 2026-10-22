class AppointmentSerializer
  def initialize(appointment)
    @appointment = appointment
  end

  def as_json(*)
    {
      id: @appointment.id,
      user_id: @appointment.user_id,
      client_id: @appointment.client_id,
      resource_id: @appointment.resource_id,
      client: serialized_client,
      resource: serialized_resource,
      scheduled_at: @appointment.scheduled_at.iso8601,
      status: @appointment.status,
      duration_minutes: @appointment[:duration_minutes],
      duration_overridden: @appointment.duration_overridden,
      services: serialized_services,
    }
  end

  private

  def serialized_services
    appointment_services =
      if @appointment.association(:appointment_services).loaded?
        @appointment.appointment_services
      else
        @appointment.appointment_services.includes(:service)
      end

    appointment_services.map do |appointment_service|
      ServiceSerializer.new(appointment_service.service).as_json.merge(
        price: appointment_service.price_at_booking
      )
    end
  end

  def serialized_client
    return nil unless @appointment.client

    {
      id: @appointment.client.id,
      first_name: @appointment.client.first_name,
      last_name: @appointment.client.last_name,
    }
  end

  def serialized_resource
    ResourceSerializer.new(@appointment.resource).as_json
  end
end
