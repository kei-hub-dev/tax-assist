class BooksController < ApplicationController
  before_action :require_accounting_period!

  def journal
    @period = current_period
    @entries = JournalEntry.includes(journal_entry_lines: :account)
                           .where(accounting_period_id: @period.id)
                           .order(:entry_date, :entry_no, :id)

    base = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: @period.id })
    totals = base.group(:dc).sum(:amount)
    @total_debit  = totals["debit"].to_i
    @total_credit = totals["credit"].to_i
  end
end
