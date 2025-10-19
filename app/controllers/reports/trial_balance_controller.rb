class Reports::TrialBalanceController < ApplicationController
  before_action :require_accounting_period!

  def show
    period_id = current_period.id
    accounts  = current_user.accounts.pluck(:id, :name).to_h

    base = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: period_id })
    debits  = base.where(dc: "debit").group(:account_id).sum(:amount)
    credits = base.where(dc: "credit").group(:account_id).sum(:amount)

    ids = debits.keys | credits.keys

    rows = ids.map do |account_id|
      debit  = debits[account_id].to_i
      credit = credits[account_id].to_i
      { account_name: accounts[account_id], debit: debit, credit: credit, balance: debit - credit }
    end

    rows.reject! { |row| row[:debit].zero? && row[:credit].zero? }

    @rows         = rows.sort_by { |row| row[:account_name].to_s }
    @total_debit  = @rows.sum { |row| row[:debit] }
    @total_credit = @rows.sum { |row| row[:credit] }
    @balanced     = (@total_debit == @total_credit)
  end
end
