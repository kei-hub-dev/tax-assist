class OpeningBalance < ApplicationRecord
  belongs_to :accounting_period
  belongs_to :account
  validates :debit_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :credit_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :only_one_side

  private

  def only_one_side
    return if debit_amount.to_i.zero? || credit_amount.to_i.zero?
    errors.add(:base, "借方と貸方の両方に金額は入力できません")
  end
end
