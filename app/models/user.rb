class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :accounting_periods, dependent: :destroy
  has_many :accounts, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_email
  after_create :setup_default_periods

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def setup_default_periods
    (2024..Date.current.year).each do |y|
      accounting_periods.find_or_create_by!(accounting_year: y)
    end
  end
end
