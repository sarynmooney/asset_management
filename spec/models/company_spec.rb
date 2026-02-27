require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      company = create(:company)
      expect(company).to be_valid
    end
  end
end
