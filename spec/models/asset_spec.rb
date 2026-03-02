require 'rails_helper'

RSpec.describe Asset, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      asset = create(:asset)
      expect(asset).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a company' do
      asset = create(:asset)
      expect(asset.company).to be_present
    end

    it 'has many maintenance records' do
      asset = create(:asset)
      expect(asset.maintenance_records).to include(create(:maintenance_record, asset: asset))
    end

    it 'has many software licenses' do
      asset = create(:asset)
      expect(asset.software_licenses).to include(create(:software_license, asset: asset))
    end

    it 'has many notes' do
      asset = create(:asset)
      expect(asset.notes).to include(create(:note, asset: asset))
    end
  end
end
