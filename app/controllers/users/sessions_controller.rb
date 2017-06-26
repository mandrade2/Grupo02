class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  def create_facebook
    user = User.from_omniauth(session["devise.facebook_data"])
    log_in user
    redirect_back_or user
  end


  #def destroy
  #  super
  #  reset_session
  #end
  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute, :info, :uid, :extra, :credentials, :code, :state,:image,:username])
  end
end
