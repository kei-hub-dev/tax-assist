class AccountController < ApplicationController
  before_action :reject_google_authenticated_user!, only: [ :email, :password ]

  def edit; end

  def email
    new_email = params[:new_email].to_s.strip

    if new_email.blank?
      flash.now[:alert] = "新しいメールアドレスを入力してください"
      return render :edit, status: :unprocessable_entity
    end

    if current_user.update(email: new_email)
      if current_user.saved_change_to_email?
        redirect_to authenticated_root_path, notice: "メールアドレスを更新しました"
      else
        flash.now[:alert] = "メールアドレスは変更されていません"
        render :edit, status: :unprocessable_entity
      end
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

  def password_params
    params.permit(:password, :password_confirmation)
  end

  def reject_google_authenticated_user!
    return unless current_user.google_authenticated?

    redirect_to edit_user_account_path, alert: "Googleログインユーザーはメール/パスワードを変更できません"
  end
end
