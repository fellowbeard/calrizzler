class AccountSerializer
  def initialize(account)
    @account = account
  end

  def as_json(*)
    {
      id: @account.id,
      business_name: @account.business_name,
      timezone: @account.timezone,
      resources: @account.resources.map do |resource|
        ResourceSerializer.new(resource).as_json
      end,
    }
  end
end
