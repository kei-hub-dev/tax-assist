require "csv"

class Reports::GeneralLedgerController < ApplicationController
  before_action :authenticate_user!
  before_action :require_accounting_period!

  def show
    period_id = current_period.id

    lines = JournalEntryLine.joins(:journal_entry)
                            .where(journal_entries: { accounting_period_id: period_id })
                            .select(:account_id, :dc, :amount)

    debit_sum  = Hash.new(0)
    credit_sum = Hash.new(0)

    lines.each do |l|
      amt = l.amount.to_i
      if l.dc.to_s == "debit"
        debit_sum[l.account_id]  += amt
      elsif l.dc.to_s == "credit"
        credit_sum[l.account_id] += amt
      end
    end

    ids   = (debit_sum.keys + credit_sum.keys).uniq
    names = current_user.accounts.where(id: ids).pluck(:id, :name).to_h

    @rows = ids.map do |id|
      d = debit_sum[id].to_i
      c = credit_sum[id].to_i
      { account_id: id, account_name: (names[id] || "(不明)"), debit: d, credit: c, balance: d - c }
    end.sort_by { |r| r[:account_name].to_s }

    respond_to do |format|
      format.html
      format.csv do
        csv = CSV.generate(force_quotes: true) do |c|
          c << %w[勘定科目 借方合計 貸方合計 差額（借方−貸方）]
          @rows.each { |r| c << [ r[:account_name], r[:debit], r[:credit], r[:balance] ] }
        end
        send_data csv, filename: "general_ledger_#{current_period.accounting_year}.csv", type: "text/csv"
      end
      format.pdf do
        html = render_to_string(action: :show, layout: "pdf", formats: [ :html ])
        pdf  = Grover.new(html).to_pdf
        send_data pdf, filename: "general_ledger_#{current_period.accounting_year}.pdf",
                  type: "application/pdf", disposition: "attachment"
      end
    end
  end
end
