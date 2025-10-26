require "csv"

class Reports::GeneralLedgerController < ApplicationController
  before_action :require_accounting_period!

  def show
    period_id = current_period.id

    lines = JournalEntryLine
              .joins(:journal_entry)
              .where(journal_entries: { accounting_period_id: period_id })
              .select(:account_id, :dc, :amount)

    debit_totals  = Hash.new(0)
    credit_totals = Hash.new(0)

    lines.each do |line|
      amount = line.amount.to_i
      case line.dc.to_s
      when "debit"  then debit_totals[line.account_id]  += amount
      when "credit" then credit_totals[line.account_id] += amount
      end
    end

    account_ids = (debit_totals.keys + credit_totals.keys).uniq

    account_records = current_user.accounts
                         .where(id: account_ids)
                         .select(:id, :name, :category)
                         .index_by(&:id)

    @rows = account_ids.map do |account_id|
      account     = account_records[account_id]
      debit_sum   = debit_totals[account_id].to_i
      credit_sum  = credit_totals[account_id].to_i
      category    = account.category.to_s

      {
        account_id:   account_id,
        account_name: account.name,
        category:     category,
        debit:        debit_sum,
        credit:       credit_sum,
        balance:      debit_sum - credit_sum
      }
    end

    category_order = { "asset" => 0, "liability" => 1, "equity" => 2, "revenue" => 3, "expense" => 4 }
    @rows.sort_by! { |row| [ category_order.fetch(row[:category], 99), row[:account_name].to_s ] }

    @total_debit   = @rows.sum { |r| r[:debit] }
    @total_credit  = @rows.sum { |r| r[:credit] }
    @total_balance = @rows.sum { |r| r[:balance] }
    @balanced      = (@total_debit == @total_credit)

    respond_to do |format|
      format.html
      format.csv do
        csv = CSV.generate(force_quotes: true) do |csv_builder|
          csv_builder << %w[カテゴリ 勘定科目 借方合計 貸方合計 差額（借方－貸方）]
          @rows.each do |row|
            csv_builder << [
              I18n.t("accounts.categories.#{row[:category]}", default: row[:category]),
              row[:account_name],
              row[:debit],
              row[:credit],
              row[:balance]
            ]
          end
          csv_builder << [ "合計", "", @total_debit, @total_credit, @total_balance ]
        end
        send_data csv, filename: "general_ledger_#{current_period.accounting_year}.csv", type: "text/csv"
      end
      format.pdf do
        html = render_to_string(action: :show, layout: "pdf", formats: [ :html ])
        pdf  = Grover.new(
          html,
          display_url: request.original_url,
          format: "A4",
          launch_args: %w[--no-sandbox --disable-dev-shm-usage --disable-gpu]
        ).to_pdf
        send_data pdf,
          filename: "balance_sheet_#{current_period.accounting_year}.pdf",
          type: "application/pdf",
          disposition: "attachment"
      end
    end
  end
end
