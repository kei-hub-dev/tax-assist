class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :devise_controller?

  helper_method :current_period

  def current_period
    pid = session[:accounting_period_id]
    return unless pid && current_user
    @current_period ||= current_user.accounting_periods.find_by(id: pid)
  end

  def require_accounting_period!
    redirect_to authenticated_root_path, alert: "会計年度を選択してください" unless current_period
  end
end
