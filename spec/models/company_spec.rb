require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      company = create(:company)
      expect(company).to be_valid
    end
  end

  # describe 'associations' do
  #   it 'has many assets' do
  #     company = create(:company)
  #     expect(company.assets).to eq(company.assets)
  #   end
 
  #   it 'has many contacts' do
  #     company = create(:company)
  #     expect(company.contacts).to eq(company.contacts)
  #   end
  # end
end
