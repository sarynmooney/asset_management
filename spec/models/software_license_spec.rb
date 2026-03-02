require 'rails_helper'

RSpec.describe SoftwareLicense, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      software_license = create(:software_license)
      expect(software_license).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to an asset' do
      software_license = create(:software_license)
      expect(software_license.asset).to be_present
    end
  end
end
