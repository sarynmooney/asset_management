class SoftwareLicense < ApplicationRecord
  belongs_to :asset

  validates :software_name, presence: true
  validates :expiration_date, presence: true
end
