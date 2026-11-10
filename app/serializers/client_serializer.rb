class ClientSerializer
  def initialize(client)
    @client = client
  end

  def as_json(*)
    {
      id: @client.id,
      user_id: @client.user_id,
      first_name: @client.first_name,
      last_name: @client.last_name,
      email: @client.email,
      phone: @client.phone,
      address_line1: @client.address_line1,
      address_line2: @client.address_line2,
      city: @client.city,
      state: @client.state,
      postal_code: @client.postal_code,
    }
  end
end
