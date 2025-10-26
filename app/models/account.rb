class Account < ApplicationRecord
  belongs_to :user

  SUB_KEYS = %w[sales cogs sganda non_op_income non_op_expense special_gain special_loss tax].freeze

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :category, presence: true,
                       inclusion: { in: I18n.t("accounts.categories").keys.map(&:to_s) }
  validate :validate_sub_category

  before_validation :normalize_category
  before_validation :normalize_sub_category

  private

  def normalize_category
    self.category = category.to_s.strip.presence
  end

  def revenue_or_expense?
    category.in?(%w[revenue expense])
  end

  def normalize_sub_category
    self.sub_category = nil unless revenue_or_expense?
  end

  def validate_sub_category
    return unless revenue_or_expense?
    errors.add(:sub_category, :invalid) unless SUB_KEYS.include?(sub_category)
  end
end
