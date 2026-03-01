class Contact < ApplicationRecord
  ROLES = %w[primary technical billing].freeze
  belongs_to :company

  validates :name, presence: true
  validates :email, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }
end
