class AccountingMenuController < ApplicationController
  before_action :require_accounting_period!

  def show
    @period = current_period
  end
end
