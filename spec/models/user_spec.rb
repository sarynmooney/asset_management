require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = create(:user)
      expect(user).to be_valid
    end
  end

  # describe 'associations' do
  #   it 'has many notes' do
  #     user = create(:user)
  #     expect(user.notes).to eq(user.notes)
  #   end
  # end
end
