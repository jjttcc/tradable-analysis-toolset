require 'ruby_contracts'

class ApplicationController < ActionController::Base
  protect_from_forgery
  # Note: 'include Contracts::DSL' causes catastrophic test failure, so do
  # without executable contracts in this class.
  include SessionsHelper

  helper_method :mas_client, :symbol_list, :period_types

  def index
    @motd = MOTD.new
  end

  public ###  Access

  # MasClient object for the current user
  # pre :signed_in do signed_in? end
  def mas_client
    if @mas_client.nil?
      @mas_client = MasClientTools::mas_client(user: current_user)
    end
    @mas_client
  end

  # pre :signed_in do signed_in? end
  def symbol_list
    ##!!!Fix needed: Get from current_user.mas_session instead of
    ##!!!mas_client.
    if @symbols.nil?
      client = mas_client
      client.request_symbols
      @symbols = client.symbols
    end
    @symbols
  end

  # pre :signed_in do signed_in? end
  def period_types
    ##!!!Fix needed: Get from current_user.mas_session instead of
    ##!!!mas_client.
    if @period_types.nil?
      symbols = symbol_list
      if symbols != nil and symbols.length > 0
        client = mas_client
        client.request_period_types(symbols.first)
        @period_types = client.period_types
      end
    end
    @period_types
  end

  protected

  def store_location
    session[:return_to] = request.fullpath
  end

  def deny_access
    store_location
    redirect_to signin_path, :notice => "Please sign in."
  end

  def redirect_back_or_to(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  def clear_return_to
    session.delete(:return_to)
  end

  def authenticate
    if not signed_in?
      deny_access
    end
  end

end
