class OpeningBalancesController < ApplicationController
  before_action :require_accounting_period!
  before_action :set_period_and_accounts

  CATEGORY_ORDER = { "asset"=>1, "liability"=>2, "equity"=>3, "revenue"=>4, "expense"=>5 }

  def show
    @prev_year = @period.accounting_year.to_i - 1
    @balances = OpeningBalance.where(accounting_period: @period, account_id: @account_ids).index_by(&:account_id)
    @total_debit  = @balances.values.sum { |b| b.debit_amount.to_i }
    @total_credit = @balances.values.sum { |b| b.credit_amount.to_i }
  end

  def update
    if @accounts.empty?
      redirect_to opening_balances_path, alert: "まず勘定科目を作成してください"
      return
    end

    balance_rows = opening_balance_params

    ActiveRecord::Base.transaction do
      balance_rows.each do |account_id, amounts|
        opening_balance = OpeningBalance.find_or_initialize_by(accounting_period: @period, account_id: account_id)
        opening_balance.update!(
          debit_amount:  amounts[:debit_amount].to_i,
          credit_amount: amounts[:credit_amount].to_i
        )
      end
    end

    redirect_to opening_balances_path, notice: "開始残高を保存しました"
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "保存に失敗しました"
    show
    render :show, status: :unprocessable_entity
  end

  private

  def set_period_and_accounts
    @period = current_period
    accounts = current_user.accounts.to_a
    @accounts = accounts.sort_by { |a| [ CATEGORY_ORDER[a.category] || 99, a.name ] }
    @account_ids = accounts.map(&:id)
  end

  def opening_balance_params
    raw = params.require(:opening_balances)
    safe = {}
    @account_ids.each do |id|
      key = id.to_s
      next unless raw[key].is_a?(ActionController::Parameters)
      safe[id] = raw.require(key).permit(:debit_amount, :credit_amount)
    end
    safe
  end
end
