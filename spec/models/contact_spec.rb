require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      contact = create(:contact)
      expect(contact).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a company' do
      contact = create(:contact)
      expect(contact.company).to be_present
    end
  end
end
