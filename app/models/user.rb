class User < ApplicationRecord
  has_one :address
  accepts_nested_attributes_for :address
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :nickname, :family_name, :first_name, :family_furigana, :first_furigana, :birth_year, :birth_month, :birth_day,presence: true
end
