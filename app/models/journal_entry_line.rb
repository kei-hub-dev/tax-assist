class JournalEntryLine < ApplicationRecord
  belongs_to :journal_entry, inverse_of: :journal_entry_lines
  belongs_to :account

  DC_VALUES = %w[debit credit].freeze

  validates :account_id, presence: true
  validates :dc, inclusion: { in: DC_VALUES }
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
end
