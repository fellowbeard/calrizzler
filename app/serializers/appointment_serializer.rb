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
      scheduled_at: @appointment.scheduled_at.strftime('%Y-%m-%dT%H:%M:%S'),
      status: @appointment.status,
      duration_minutes: @appointment[:duration_minutes],
      duration_overridden: @appointment.duration_overridden,
      services: @appointment.services.map do |service|
        ServiceSerializer.new(service).as_json
      end,
    }
  end

  private

  def serialized_client
    return nil unless @appointment.client

    {
      id: @appointment.client.id,
      first_name: @appointment.client.first_name,
      last_name: @appointment.client.last_name,
    }
  end

  def serialized_resource
    return nil unless @appointment.resource

    ResourceSerializer.new(@appointment.resource).as_json
  end
end