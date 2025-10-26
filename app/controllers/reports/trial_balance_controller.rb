class Reports::TrialBalanceController < ApplicationController
  before_action :require_accounting_period!

  def show
    period_id = current_period.id

    base    = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: period_id })
    debits  = base.where(dc: "debit").group(:account_id).sum(:amount)
    credits = base.where(dc: "credit").group(:account_id).sum(:amount)

    account_ids = debits.keys | credits.keys

    account_records = current_user.accounts
                         .where(id: account_ids)
                         .select(:id, :name, :category)
                         .index_by(&:id)

    rows = account_ids.map do |account_id|
      account    = account_records[account_id]
      debit_sum  = debits[account_id].to_i
      credit_sum = credits[account_id].to_i

      {
        account_id:   account_id,
        account_name: account.name,
        category:     account.category.to_s,
        debit:        debit_sum,
        credit:       credit_sum,
        balance:      debit_sum - credit_sum
      }
    end

    order_index = { "asset" => 0, "liability" => 1, "equity" => 2, "revenue" => 3, "expense" => 4 }
    rows.sort_by! { |r| [ order_index.fetch(r[:category], 99), r[:account_name].to_s ] }
    rows.reject!  { |r| r[:debit].zero? && r[:credit].zero? }

    @rows         = rows
    @total_debit  = @rows.sum { |r| r[:debit] }
    @total_credit = @rows.sum { |r| r[:credit] }
    @balanced     = (@total_debit == @total_credit)
  end
end
