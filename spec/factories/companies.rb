FactoryBot.define do
  factory :company do
    name { Faker::Company.unique.name }
    city { Faker::Address.city }
    state { Faker::Address.state }
  end
end
