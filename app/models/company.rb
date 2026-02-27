class Company < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :city, presence: true

  # has_many :assets
  # has_many :contacts
end
