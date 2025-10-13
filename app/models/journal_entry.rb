class JournalEntry < ApplicationRecord
  belongs_to :accounting_period
  has_many :journal_entry_lines, dependent: :destroy
  accepts_nested_attributes_for :journal_entry_lines, allow_destroy: true

  validates :entry_no, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :entry_date, presence: true

  scope :recent, -> { order(entry_date: :desc, entry_no: :desc) }

  before_validation :assign_entry_no, on: :create

  private

  def assign_entry_no
    return if entry_no.present?
    last_no = JournalEntry.where(accounting_period_id: accounting_period_id).maximum(:entry_no)
    self.entry_no = (last_no || 0) + 1
  end
end
