class AccountController < ApplicationController
  def edit; end

  def email
    if current_user.update(email_params)
      redirect_to authenticated_root_path, notice: "メールアドレスを更新しました"
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def password
    if current_user.update(password_params)
      bypass_sign_in(current_user)
      redirect_to authenticated_root_path, notice: "パスワードを更新しました"
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def email_params
    params.permit(:email)
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
