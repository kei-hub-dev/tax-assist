class AccountingMenuController < ApplicationController
  before_action :authenticate_user!

  def show
    @period = current_user.accounting_periods.find_by(id: session[:accounting_period_id])
    unless @period
      redirect_to authenticated_root_path, alert: "会計年度を選択してください"
      nil
    end
  end
end
