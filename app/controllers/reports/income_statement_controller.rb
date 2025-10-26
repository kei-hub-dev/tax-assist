require "csv"

class Reports::IncomeStatementController < ApplicationController
  before_action :require_accounting_period!

  def show
    period_id = current_period.id

    base = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: period_id })

    revenue_by_subcategory = base.where(dc: "credit").joins(:account).where(accounts: { category: "revenue" })
                                 .group("COALESCE(accounts.sub_category, 'sales')").sum(:amount)
    expense_by_subcategory = base.where(dc: "debit").joins(:account).where(accounts: { category: "expense" })
                                 .group("COALESCE(accounts.sub_category, 'sganda')").sum(:amount)

    @revenue_totals = {
      "sales"         => revenue_by_subcategory["sales"].to_i,
      "non_op_income" => revenue_by_subcategory["non_op_income"].to_i,
      "special_gain"  => revenue_by_subcategory["special_gain"].to_i
    }

    @expense_totals = {
      "cogs"           => expense_by_subcategory["cogs"].to_i,
      "sganda"         => expense_by_subcategory["sganda"].to_i,
      "non_op_expense" => expense_by_subcategory["non_op_expense"].to_i,
      "special_loss"   => expense_by_subcategory["special_loss"].to_i,
      "tax"            => expense_by_subcategory["tax"].to_i
    }

    sales          = @revenue_totals["sales"]
    non_op_income  = @revenue_totals["non_op_income"]
    special_gain   = @revenue_totals["special_gain"]
    cogs           = @expense_totals["cogs"]
    sganda         = @expense_totals["sganda"]
    non_op_expense = @expense_totals["non_op_expense"]
    special_loss   = @expense_totals["special_loss"]
    tax            = @expense_totals["tax"]

    @gross_profit      = sales - cogs
    @operating_income  = @gross_profit - sganda
    @ordinary_income   = @operating_income + non_op_income - non_op_expense
    @income_before_tax = @ordinary_income + special_gain - special_loss
    @net_income        = @income_before_tax - tax

    revenue_order = %w[sales non_op_income special_gain]
    expense_order = %w[cogs sganda non_op_expense special_loss tax]

    @revenue_breakdown = revenue_by_subcategory
      .transform_keys { |k| k.to_s.presence || "sales" }
      .map { |sub_key, amount| amount_i = amount.to_i; next if amount_i.zero?; { key: sub_key, label: I18n.t("accounts.sub_categories.revenue.#{sub_key}", default: sub_key), amount: amount_i } }
      .compact
      .sort_by { |h| [ revenue_order.index(h[:key]) || 99, h[:key] ] }

    @expense_breakdown = expense_by_subcategory
      .transform_keys { |k| k.to_s.presence || "sganda" }
      .map { |sub_key, amount| amount_i = amount.to_i; next if amount_i.zero?; { key: sub_key, label: I18n.t("accounts.sub_categories.expense.#{sub_key}", default: sub_key), amount: amount_i } }
      .compact
      .sort_by { |h| [ expense_order.index(h[:key]) || 99, h[:key] ] }

    respond_to do |format|
      format.html
      format.csv do
        csv = CSV.generate(force_quotes: true) do |csv_builder|
          csv_builder << %w[項目 金額]
          csv_builder << [ "売上高", sales ]
          csv_builder << [ "売上原価", cogs ]
          csv_builder << [ "売上総利益", @gross_profit ]
          csv_builder << [ "販売費及び一般管理費", sganda ]
          csv_builder << [ "営業利益", @operating_income ]
          csv_builder << [ "営業外収益", non_op_income ]
          csv_builder << [ "営業外費用", non_op_expense ]
          csv_builder << [ "経常利益", @ordinary_income ]
          csv_builder << [ "特別利益", special_gain ]
          csv_builder << [ "特別損失", special_loss ]
          csv_builder << [ "税引前当期純利益", @income_before_tax ]
          csv_builder << [ "税等", tax ]
          csv_builder << [ "当期純利益", @net_income ]
        end
        send_data csv, filename: "income_statement_#{current_period.accounting_year}.csv", type: "text/csv"
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
          filename: "income_statement_#{current_period.accounting_year}.pdf",
          type: "application/pdf",
          disposition: "attachment"
      end
    end
  end
end
