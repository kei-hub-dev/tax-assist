class Account < ApplicationRecord
  belongs_to :user
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :category, presence: true, inclusion: { in: I18n.t("accounts.categories").keys }
  SUB_KEYS = %w[sales cogs sganda non_op_income non_op_expense special_gain special_loss tax]
  validate :validate_sub_category

  private

  def validate_sub_category
    if %w[revenue expense].include?(category)
      errors.add(:sub_category, :invalid) unless SUB_KEYS.include?(sub_category)
    else
      self.sub_category = nil
    end
  end
end
