
class SessionsController < ApplicationController
  include ControllerFacilities
  include Contracts::DSL

  public

  SIGN_IN_TITLE = 'Sign in'

  def new
    @title = SIGN_IN_TITLE
  end

  pre :params_session_exists do params != nil && params[:session] != nil end
  def create
    user = User.authenticated(params[:session][:email_addr],
                              params[:session][:password])
    if user != nil
      sign_in user
      if mas_client == nil
        fail_login("Failed to connect to MAS server #{@error_msg}.")
      else
        redirect_back_or_to user
      end
    else
      retry_login("Invalid email/password combination")
    end
  end

  pre :params_session_exists do params != nil && params[:session] != nil end
  def alternate_create__probably_discard  #!!!!!!!!!!!!!!!!!!!!
    user = User.authenticated(params[:session][:email_addr],
                              params[:session][:password])
    if user != nil
      sign_in user
      need_next_port = false
      used_port_count = 0
      connected = false
      while ! connected && used_port_count < number_of_available_ports do
        if mas_client(request_next_port: need_next_port) == nil then
          fail_login("Failed to connect to MAS server #{@error_msg}.")
        elsif mas_client.communication_failed then
          $log.warn("Failure - comm with MAS server [need to handle!!!]" +
                    "#{@error_msg}.")
          need_next_port = true
        else
          connected = true
          redirect_back_or_to user
        end
        used_port_count += 1
      end
    else
      retry_login("Invalid email/password combination")
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end

  private

  def retry_login(msg)
      flash.now[:error] = msg
      @title = SIGN_IN_TITLE
      render 'new'
  end

  def fail_login(msg)
      flash.now[:error] = msg
      sign_out
      render 'new'
  end

end
