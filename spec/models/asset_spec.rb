require 'rails_helper'

RSpec.describe Asset, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      asset = create(:asset)
      expect(asset).to be_valid
    end
  end
end
