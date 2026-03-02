FactoryBot.define do
  factory :note do
    content { Faker::Lorem.sentence }
    asset
    author { create(:user) }
  end
end
