class AccountsController < ApplicationController
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @accounts = current_user.accounts.order(:category, :name)
  end

  def sub_categories
    @accounts = current_user.accounts.where(category: %w[revenue expense]).order(:category, :name)
  end

  def update_sub_categories
    rows = params.require(:accounts)

    ids = rows.keys.grep(/\A\d+\z/).map(&:to_i)
    accounts = current_user.accounts.where(id: ids).index_by(&:id)

    rows.each do |id_str, attrs|
      account_to_update = accounts[id_str.to_i]
      next unless account_to_update

      permitted = ActionController::Parameters.new(attrs).permit(:sub_category)
      value = permitted[:sub_category].presence
      account_to_update.update(sub_category: value)
    end

    redirect_to accounts_path, notice: "サブ区分を更新しました"
  end

  def show
    redirect_to edit_account_path(@account)
  end

  def new
    @account = current_user.accounts.build
  end

  def create
    @account = current_user.accounts.build(account_params)
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
