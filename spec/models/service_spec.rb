require 'rails_helper'

RSpec.describe Service, type: :model do
  let(:account) { create(:account) }
  let(:service) { create(:service, account: account) }

  describe 'archiving' do
    it 'is active by default' do
      expect(service.archived?).to be false
      expect(Service.active).to include(service)
      expect(Service.archived).not_to include(service)
    end

    it 'can be archived' do
      service.archive!

      expect(service.archived?).to be true
      expect(Service.active).not_to include(service)
      expect(Service.archived).to include(service)
    end

    it 'can be restored' do
      service.archive!
      service.restore!

      expect(service.archived?).to be false
      expect(Service.active).to include(service)
      expect(Service.archived).not_to include(service)
    end
  end
end
