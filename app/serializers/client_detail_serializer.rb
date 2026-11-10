class ClientDetailSerializer
  def initialize(client)
    @client = client
  end

  def as_json(*)
    {
      id: @client.id,
      account_id: @client.account_id,
      user_id: @client.user_id,
      first_name: @client.first_name,
      last_name: @client.last_name,
      email: @client.email,
      phone: @client.phone,

      notes: @client.notes.map do |note|
        NoteSerializer.new(note).as_json
      end,

      appointments: @client.appointments.order(scheduled_at: :desc).map do |appointment|
        AppointmentSerializer.new(appointment).as_json
      end,
    }.merge(address_attributes)
  end

  private

  def address_attributes
    {
      address_line1: @client.address_line1,
      address_line2: @client.address_line2,
      city: @client.city,
      state: @client.state,
      postal_code: @client.postal_code,
    }
  end
end
