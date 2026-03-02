require 'rails_helper'

RSpec.describe Note, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      note = create(:note)
      expect(note).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to an asset' do
      note = create(:note)
      expect(note.asset).to be_present
    end
    
    it 'belongs to an author' do
      note = create(:note)
      expect(note.author).to be_present
    end
  end
end
