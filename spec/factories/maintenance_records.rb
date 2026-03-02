FactoryBot.define do
  factory :maintenance_record do
    description { Faker::Lorem.sentence }
    performed_at { Faker::Time.between(from: 1.year.ago, to: Time.current) }
    cost { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    asset
  end
end
