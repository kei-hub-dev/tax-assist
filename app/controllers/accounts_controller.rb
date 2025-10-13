# app/controllers/accounts_controller.rb
class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @accounts = current_user.accounts.order(:category, :name)
  end

  def sub_categories
    @accounts = current_user.accounts.where(category: %w[revenue expense]).order(:category, :name)
  end

  def update_sub_categories
    raw = params.require(:accounts).permit!
    ids = raw.keys
    current_user.accounts.where(id: ids).find_each do |acc|
      acc.update(sub_category: raw[acc.id.to_s][:sub_category].presence)
    end
    redirect_to accounts_path, notice: "サブ区分を更新しました"
  end

  def show
    redirect_to edit_account_path(@account)
  end

  def new
    @account = current_user.accounts.new
  end

  def create
    @account = current_user.accounts.new(account_params)
    if @account.save
      redirect_to accounts_path, notice: "勘定科目を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @account.update(account_params)
      redirect_to accounts_path, notice: "勘定科目を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    redirect_to accounts_path, notice: "勘定科目を削除しました"
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:name, :category, :sub_category)
  end
end
