class Reports::BalanceSheetController < ApplicationController
  before_action :authenticate_user!
  before_action :require_accounting_period!

  def show
    period_id = current_period.id

    ob_map = OpeningBalance.where(accounting_period_id: period_id).index_by(&:account_id)

    base    = JournalEntryLine.joins(:journal_entry).where(journal_entries: { accounting_period_id: period_id })
    debits  = base.where(dc: "debit").group(:account_id).sum(:amount)
    credits = base.where(dc: "credit").group(:account_id).sum(:amount)

    period_net = Hash.new(0)
    (debits.keys | credits.keys).each do |aid|
      period_net[aid] = debits[aid].to_i - credits[aid].to_i
    end

    @assets, @liabs, @equities = [], [], []
    @total_assets_open = @total_assets_move = @total_assets_end = 0
    @total_leq_open    = @total_leq_move    = @total_leq_end    = 0

    accounts = current_user.accounts.where(category: %w[asset liability equity]).order(:category, :id).to_a

    accounts.each do |acc|
      open_net = ob_map[acc.id] ? (ob_map[acc.id].debit_amount.to_i - ob_map[acc.id].credit_amount.to_i) : 0
      move_net = period_net[acc.id]
      end_net  = open_net + move_net

      case acc.category
      when "asset"
        o = open_net
        m = move_net
        e = end_net
        @assets << { name: acc.name, open: o, move: m, end: e }
        @total_assets_open += o
        @total_assets_move += m
        @total_assets_end  += e
      when "liability", "equity"
        o = -open_net
        m = -move_net
        e = -end_net
        row = { name: acc.name, open: o, move: m, end: e }
        if acc.category == "liability"
          @liabs << row
        else
          @equities << row
        end
        @total_leq_open += o
        @total_leq_move += m
        @total_leq_end  += e
      end
    end

    respond_to do |format|
      format.html
      format.csv do
        csv = CSV.generate(force_quotes: true) do |c|
          c << %w[区分 科目 開始残高 当期増減 期末残高]
          @assets.each  { |r| c << [ "資産", r[:name], r[:open], r[:move], r[:end] ] }
          c << [ "資産合計", "", @total_assets_open, @total_assets_move, @total_assets_end ]
          @liabs.each    { |r| c << [ "負債", r[:name], r[:open], r[:move], r[:end] ] }
          @equities.each { |r| c << [ "純資産", r[:name], r[:open], r[:move], r[:end] ] }
          c << [ "負債・純資産合計", "", @total_leq_open, @total_leq_move, @total_leq_end ]
        end
        send_data csv, filename: "balance_sheet_#{current_period.accounting_year}.csv", type: "text/csv"
      end
      format.pdf do
        html = render_to_string(action: :show, layout: "pdf", formats: [ :html ])
        pdf  = Grover.new(html).to_pdf
        send_data pdf, filename: "balance_sheet_#{current_period.accounting_year}.pdf", type: "application/pdf", disposition: "attachment"
      end
    end
  end
end
