class JournalEntryLine < ApplicationRecord
  belongs_to :journal_entry, inverse_of: :journal_entry_lines
  belongs_to :account
  validates :account_id, presence: true
  validates :dc, inclusion: { in: %w[debit credit] }
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
end
