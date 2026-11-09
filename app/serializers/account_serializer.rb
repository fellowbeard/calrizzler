
class AccountSerializer
  def initialize(account)
    @account = account
  end

  def as_json(*)
    {
      id: @account.id,
      business_name: @account.business_name,
      timezone: @account.timezone,
      phone: @account.phone,
      address_line1: @account.address_line1,
      address_line2: @account.address_line2,
      city: @account.city,
      state: @account.state,
      postal_code: @account.postal_code,
      resources: @account.resources.map do |resource|
        ResourceSerializer.new(resource).as_json
      end,
    }
  end
end
