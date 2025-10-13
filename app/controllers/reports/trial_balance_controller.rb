class Reports::TrialBalanceController < ApplicationController
  before_action :authenticate_user!
  before_action :require_accounting_period!

  def show
    period_id = current_period.id
    accounts = current_user.accounts.select(:id, :name).to_h { |a| [a.id, a.name] }

    base = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: period_id })
    debits  = base.where(dc: "debit").group(:account_id).sum(:amount)
    credits = base.where(dc: "credit").group(:account_id).sum(:amount)

    ids = (debits.keys + credits.keys).uniq

    rows = ids.map do |account_id|
      d = debits[account_id].to_i
      c = credits[account_id].to_i
      { "account_name" => accounts[account_id] || "(不明)", "debit" => d, "credit" => c, "balance" => d - c }
    end

    rows.reject! { |r| r["debit"].to_i.zero? && r["credit"].to_i.zero? }

    @rows = rows.sort_by { |r| r["account_name"].to_s }
    @total_debit  = @rows.sum { |r| r["debit"].to_i }
    @total_credit = @rows.sum { |r| r["credit"].to_i }
    @balanced     = (@total_debit == @total_credit)
  end
end
