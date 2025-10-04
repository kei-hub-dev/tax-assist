class BusinessController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(business_params)
      redirect_to edit_business_path, notice: "事業者情報を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def business_params
    params.require(:user).permit(:business_name)
  end
end
