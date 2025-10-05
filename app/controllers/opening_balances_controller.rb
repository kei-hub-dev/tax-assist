class OpeningBalancesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_accounting_period!

  CATEGORY_ORDER = { "asset"=>1, "liability"=>2, "equity"=>3, "revenue"=>4, "expense"=>5 }

  def show
    @period   = current_user.accounting_periods.find(session[:accounting_period_id])
    @prev_year = @period.accounting_year.to_i - 1
    @accounts = current_user.accounts.to_a.sort_by { |a| [ CATEGORY_ORDER[a.category] || 99, a.name ] }
    @balances = OpeningBalance.where(
      accounting_period: @period,
      account_id: @accounts.map(&:id)
    ).index_by(&:account_id)

    @total_debit  = @balances.values.sum { |b| b.debit_amount.to_i }
    @total_credit = @balances.values.sum { |b| b.credit_amount.to_i }
  end

  def update
    @period = current_user.accounting_periods.find(session[:accounting_period_id])
    @accounts = current_user.accounts
    if @accounts.empty?
      redirect_to opening_balances_path, alert: "まず勘定科目を作成してください"
      return
    end

    raw = params.require(:opening_balances).permit!.to_h

    ActiveRecord::Base.transaction do
      raw.each do |account_id, attrs|
        ob = OpeningBalance.find_or_initialize_by(accounting_period: @period, account_id: account_id)
        ob.debit_amount  = attrs[:debit_amount].to_i
        ob.credit_amount = attrs[:credit_amount].to_i
        ob.save!
      end
    end

    redirect_to opening_balances_path, notice: "開始残高を保存しました"
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "保存に失敗しました"
    show
    render :show, status: :unprocessable_entity
  end

  private

  def require_accounting_period!
    redirect_to authenticated_root_path, alert: "会計年度を選択してください" unless session[:accounting_period_id].present?
  end
end
