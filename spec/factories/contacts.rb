FactoryBot.define do
  factory :contact do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    role { Contact::ROLES.sample }
    company
  end
end
