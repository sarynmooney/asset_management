require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      company = create(:company)
      expect(company).to be_valid
    end
  end

  describe 'associations' do
    it 'has many assets' do
      company = create(:company)
      expect(company.assets).to include(create(:asset, company: company))
    end
 
    it 'has many contacts' do
      company = create(:company)
      expect(company.contacts).to include(create(:contact, company: company))
    end
  end
end
