# app/controllers/reports/income_statement_controller.rb
require "csv"

class Reports::IncomeStatementController < ApplicationController
  before_action :authenticate_user!
  before_action :require_accounting_period!

  def show
    period_id = current_period.id

    base = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: period_id })

    rev_by_sub = base.where(dc: "credit").joins(:account).where(accounts: { category: "revenue" })
                     .group("COALESCE(accounts.sub_category, 'sales')").sum(:amount)
    exp_by_sub = base.where(dc: "debit").joins(:account).where(accounts: { category: "expense" })
                     .group("COALESCE(accounts.sub_category, 'sganda')").sum(:amount)

    @rev_breakdown = {
      "sales"          => rev_by_sub["sales"].to_i,
      "non_op_income"  => rev_by_sub["non_op_income"].to_i,
      "special_gain"   => rev_by_sub["special_gain"].to_i
    }

    @exp_breakdown = {
      "cogs"           => exp_by_sub["cogs"].to_i,
      "sganda"         => exp_by_sub["sganda"].to_i,
      "non_op_expense" => exp_by_sub["non_op_expense"].to_i,
      "special_loss"   => exp_by_sub["special_loss"].to_i,
      "tax"            => exp_by_sub["tax"].to_i
    }

    sales          = @rev_breakdown["sales"]
    non_op_income  = @rev_breakdown["non_op_income"]
    special_gain   = @rev_breakdown["special_gain"]
    cogs           = @exp_breakdown["cogs"]
    sganda         = @exp_breakdown["sganda"]
    non_op_expense = @exp_breakdown["non_op_expense"]
    special_loss   = @exp_breakdown["special_loss"]
    tax            = @exp_breakdown["tax"]

    @gross_profit      = sales - cogs
    @operating_income  = @gross_profit - sganda
    @ordinary_income   = @operating_income + non_op_income - non_op_expense
    @income_before_tax = @ordinary_income + special_gain - special_loss
    @net_income        = @income_before_tax - tax

    respond_to do |format|
      format.html
      format.csv do
        csv = CSV.generate(force_quotes: true) do |c|
          c << %w[項目 金額]
          c << [ "売上高", sales ]
          c << [ "売上原価", cogs ]
          c << [ "売上総利益", @gross_profit ]
          c << [ "販売費及び一般管理費", sganda ]
          c << [ "営業利益", @operating_income ]
          c << [ "営業外収益", non_op_income ]
          c << [ "営業外費用", non_op_expense ]
          c << [ "経常利益", @ordinary_income ]
          c << [ "特別利益", special_gain ]
          c << [ "特別損失", special_loss ]
          c << [ "税引前当期純利益", @income_before_tax ]
          c << [ "税等", tax ]
          c << [ "当期純利益", @net_income ]
        end
        send_data csv, filename: "income_statement_#{current_period.accounting_year}.csv", type: "text/csv"
      end
      format.pdf do
        html = render_to_string(action: :show, layout: "pdf", formats: [ :html ])
        pdf  = Grover.new(html).to_pdf
        send_data pdf, filename: "income_statement_#{current_period.accounting_year}.pdf", type: "application/pdf", disposition: "attachment"
      end
    end
  end
end
