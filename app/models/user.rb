class User < ApplicationRecord
  has_many :notes, foreign_key: :author_id, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
