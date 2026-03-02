FactoryBot.define do
  factory :asset do
    name { Faker::Device.unique.model_name }
    asset_type { Asset::ASSET_TYPES.sample }
    serial_number { Faker::Alphanumeric.alpha(number: 10) }
    purchase_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    company
  end
end
