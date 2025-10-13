class BooksController < ApplicationController
  before_action :authenticate_user!
  before_action :require_accounting_period!

  def journal
    @period = current_period
    @entries = JournalEntry.includes(journal_entry_lines: :account)
                           .where(accounting_period_id: @period.id)
                           .order(entry_date: :asc, entry_no: :asc, id: :asc)

    base = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: @period.id })
    @total_debit  = base.where(dc: "debit").sum(:amount).to_i
    @total_credit = base.where(dc: "credit").sum(:amount).to_i
  end
end
