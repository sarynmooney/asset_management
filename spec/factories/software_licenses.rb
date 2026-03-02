FactoryBot.define do
  factory :software_license do
    software_name { Faker::Lorem.word }
    license_key { Faker::Alphanumeric.alpha(number: 10) }
    expiration_date { Faker::Date.between(from: 1.year.ago, to: 1.year.from_now) }
    asset
  end
end
