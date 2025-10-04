class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, presence: true, lowercase: true, uniqueness: true
  has_many :accounting_periods, dependent: :destroy
  has_many :accounts, dependent: :destroy

  after_create :setup_default_periods
  def setup_default_periods
    (2024..Date.current.year).each do |y|
      accounting_periods.find_or_create_by!(accounting_year: y)
    end
  end
end
