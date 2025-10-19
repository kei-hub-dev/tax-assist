require "csv"

class Reports::GeneralLedgerController < ApplicationController
  before_action :require_accounting_period!

  def show
    period_id = current_period.id

    lines = JournalEntryLine.joins(:journal_entry)
                            .where(journal_entries: { accounting_period_id: period_id })
                            .select(:account_id, :dc, :amount)

    debit_sum  = Hash.new(0)
    credit_sum = Hash.new(0)

    lines.each do |line|
      amount = line.amount.to_i
      case line.dc.to_s
      when "debit"  then debit_sum[line.account_id]  += amount
      when "credit" then credit_sum[line.account_id] += amount
      end
    end

    ids   = (debit_sum.keys + credit_sum.keys).uniq
    names = current_user.accounts.where(id: ids).pluck(:id, :name).to_h

    @rows = ids.map { |id|
      debit  = debit_sum[id].to_i
      credit = credit_sum[id].to_i
      { account_name: names[id], account_id: id, debit: debit, credit: credit, balance: debit - credit }
    }.sort_by { |row| row[:account_name].to_s }

    respond_to do |format|
      format.html
      format.csv do
        csv = CSV.generate(force_quotes: true) do |csv_builder|
          csv_builder << %w[勘定科目 借方合計 貸方合計 差額（借方−貸方）]
          @rows.each { |row| csv_builder << [ row[:account_name], row[:debit], row[:credit], row[:balance] ] }
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
