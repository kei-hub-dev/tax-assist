class HomeController < ApplicationController
  def index
    year = Date.current.year
    periods = current_user.accounting_periods.where(accounting_year: 2024..year)
    @accounting_periods = periods.sort_by { |period| [ period.accounting_year == year ? 0 : 1, -period.accounting_year ] }
    @selected_period_id = session[:accounting_period_id] || periods.find_by(accounting_year: year)&.id
  end

  def select_accounting_period
    period = current_user.accounting_periods.find_by(id: params[:accounting_period_id])
    unless period
      redirect_to authenticated_root_path, alert: "会計年度を選択してください"
      return
    end
    session[:accounting_period_id] = period.id
    redirect_to accounting_menu_path
  end
end
