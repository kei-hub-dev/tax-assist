class Users::RegistrationsController < Devise::RegistrationsController
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    resource.assign_attributes(account_update_params)
    resource.save
    if resource.errors.empty?
      bypass_sign_in resource
      redirect_to authenticated_root_path, notice: "アカウントを更新しました"
    else
      clean_up_passwords resource
      render :edit, status: :unprocessable_entity
    end
  end

  protected

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
