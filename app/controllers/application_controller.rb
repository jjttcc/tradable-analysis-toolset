class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  # NOTE: Using Contracts::DSL in test and development causes problems in
  # this class; therefore, it is not used - pre and post are within comments.

  helper_method :mas_client, :symbol_list, :period_types,
    :period_type_start_year, :period_type_end_year

  def index
    @motd = MOTD.new
  end

  public ###  Access

  # MasClient object for the current user - nil if connection attempt to
  # server fails (and @error_msg is set to an error description)
  # pre :signed_in do signed_in? end
  def mas_client
    begin
      @error_msg = nil
      if @mas_client.nil?
        @mas_client = MasClientTools::mas_client(user: current_user)
      end
    rescue => e
      @error_msg = e.inspect
    end
    @mas_client
  end

  # pre :signed_in do signed_in? end
  # type :out => Array
  def symbol_list(no_save = false)
    if @symbols.nil?
      if current_user.mas_session != nil
        @symbols = current_user.mas_session.symbols
      end
      if @symbols.nil?
        client = mas_client
        client.request_symbols
        @symbols = client.symbols
        if current_user.mas_session != nil
          current_user.mas_session.symbols = @symbols
          if ! no_save
            current_user.mas_session.save
          end
        end
      end
    end
    @symbols
  end

  # pre :signed_in do signed_in? end
  def period_types
    if @period_types.nil?
      @period_types = current_user.mas_session.period_types
      if @period_types.nil?
        symbols = symbol_list(true)
        if symbols != nil and symbols.length > 0
          client = mas_client
          client.request_period_types(symbols.first)
          @period_types = client.period_types
          current_user.mas_session.period_types = @period_types
          current_user.mas_session.save
        end
      end
    end
    @period_types
  end

  def period_type_start_year
    Rails.configuration.earliest_year
  end

  def period_type_end_year
    Rails.configuration.latest_year
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
