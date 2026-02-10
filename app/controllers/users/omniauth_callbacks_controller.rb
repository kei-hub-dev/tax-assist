class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    auth = request.env["omniauth.auth"]

    unless User.google_email_verified?(auth)
      redirect_to new_user_session_path, alert: "Googleアカウントのメール確認が必要です"
      return
    end

    user = User.from_omniauth(auth)
    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    Rails.logger.warn("[google_oauth2] #{e.class}: #{e.message}")
    redirect_to new_user_session_path, alert: "Googleログインに失敗しました"
  end

  def failure
    redirect_to new_user_session_path, alert: "Googleログインに失敗しました"
  end
end
