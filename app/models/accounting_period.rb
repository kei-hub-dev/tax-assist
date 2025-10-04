class AccountingPeriod < ApplicationRecord
  belongs_to :user
  validates :accounting_year, presence: true
end
