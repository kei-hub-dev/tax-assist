require "csv"

class Reports::BalanceSheetController < ApplicationController
  before_action :require_accounting_period!

  def show
    period_id = current_period.id

    opening_by_account = OpeningBalance.where(accounting_period_id: period_id).index_by(&:account_id)

    base    = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: period_id })
    debits  = base.where(dc: "debit").group(:account_id).sum(:amount)
    credits = base.where(dc: "credit").group(:account_id).sum(:amount)

    period_net = Hash.new(0)
    (debits.keys | credits.keys).each do |account_id|
      period_net[account_id] = debits[account_id].to_i - credits[account_id].to_i
    end

    @assets      = []
    @liabilities = []
    @equities    = []

    accounts = current_user.accounts.where(category: %w[asset liability equity]).order(:category, :id).to_a

    accounts.each do |account|
      opening         = opening_by_account[account.id]
      opening_balance = (opening&.debit_amount).to_i - (opening&.credit_amount).to_i
      period_change   = period_net[account.id]
      ending_balance  = opening_balance + period_change

      case account.category
      when "asset"
        @assets << { name: account.name, opening: opening_balance, change: period_change, ending: ending_balance }
      when "liability", "equity"
        row = { name: account.name, opening: -opening_balance, change: -period_change, ending: -ending_balance }
        if account.category == "liability"
          @liabilities << row
        else
          @equities << row
        end
      end
    end

    @total_assets_opening = @assets.sum { |row| row[:opening] }
    @total_assets_change  = @assets.sum { |row| row[:change]  }
    @total_assets_ending  = @assets.sum { |row| row[:ending]  }

    liabilities_and_equity = @liabilities + @equities
    @total_liabilities_and_equity_opening = liabilities_and_equity.sum { |row| row[:opening] }
    @total_liabilities_and_equity_change  = liabilities_and_equity.sum { |row| row[:change]  }
    @total_liabilities_and_equity_ending  = liabilities_and_equity.sum { |row| row[:ending]  }

    respond_to do |format|
      format.html
      format.csv do
        csv = CSV.generate(force_quotes: true) do |csv_builder|
          csv_builder << %w[区分 科目 開始残高 当期増減 期末残高]
          @assets.each      { |row| csv_builder << [ "資産", row[:name], row[:opening], row[:change], row[:ending] ] }
          csv_builder << [ "資産合計", "", @total_assets_opening, @total_assets_change, @total_assets_ending ]
          @liabilities.each { |row| csv_builder << [ "負債", row[:name], row[:opening], row[:change], row[:ending] ] }
          @equities.each    { |row| csv_builder << [ "純資産", row[:name], row[:opening], row[:change], row[:ending] ] }
          csv_builder << [ "負債・純資産合計", "", @total_liabilities_and_equity_opening, @total_liabilities_and_equity_change, @total_liabilities_and_equity_ending ]
        end
        send_data csv, filename: "balance_sheet_#{current_period.accounting_year}.csv", type: "text/csv"
      end
      format.pdf do
        html = render_to_string(action: :show, layout: "pdf", formats: [ :html ])
        pdf  = Grover.new(html).to_pdf
        send_data pdf, filename: "balance_sheet_#{current_period.accounting_year}.pdf",
                  type: "application/pdf", disposition: "attachment"
      end
    end
  end
end
