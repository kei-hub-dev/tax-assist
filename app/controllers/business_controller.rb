class BusinessController < ApplicationController
  before_action :set_user

  def edit; end

  def update
    if @user.update(business_params)
      redirect_to edit_business_path, notice: "事業者情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def business_params
    params.require(:user).permit(:business_name)
  end
end
