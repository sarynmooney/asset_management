require 'rails_helper'

RSpec.describe MaintenanceRecord, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      maintenance_record = create(:maintenance_record)
      expect(maintenance_record).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to an asset' do
      maintenance_record = create(:maintenance_record)
      expect(maintenance_record.asset).to be_present
    end
  end
end
