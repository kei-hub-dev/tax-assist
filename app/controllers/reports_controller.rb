# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_accounting_period!

  def general_ledger; end
  def trial_balance; end
end
