class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  # NOTE: Using Contracts::DSL in test and development causes problems in
  # this class; therefore, it is not used - pre and post are within comments.

  helper_method :mas_client, :symbol_list, :period_types,
    :period_type_start_year, :period_type_end_year

  public

  def index
    @motd = MOTD.new
  end

  public ###  Access

  # MasClient object for the current user - nil if connection attempt to
  # server fails (and @error_msg is set to an error description).  If
  # 'request_next_port' and no more ports are available, RuntimeError is
  # raised.
  # pre :signed_in do signed_in? end
  # post :error_if_nil do |res| implies(res.nil?, not @error_msg.nil?) end
  def mas_client(request_next_port: false)
    begin
      @error_msg = nil
      if @mas_client.nil? || request_next_port then
        @mas_client = MasClientTools::mas_client(user: current_user,
                                                next_port: request_next_port)
      end
    rescue MasRuntimeError => e
      @error_msg = "Connection to MAS server failed: #{e.inspect}"
    end
    @mas_client
  end

  # pre  :signed_in do signed_in? end
  # post :result_not_nil do |result| result != nil && result.class == Array end
  # type :out => Array
  def symbol_list(no_save = false)
    if @symbols.nil? then
      if current_user.mas_session != nil then
        @symbols = current_user.mas_session.symbols
      end
      if @symbols.nil? then
        begin
          do_mas_request do
            mas_client.request_symbols
            mas_client.communication_failed
          end
          if @error_msg.nil? then
            if mas_client.communication_failed then
              flash[:error] = mas_client.last_exception.to_s
            else
              @symbols = mas_client.symbols
              if current_user.mas_session != nil then
                current_user.mas_session.symbols = @symbols
                if ! no_save then
                  current_user.mas_session.save
                end
              end
            end
          else
            flash[:error] = @error_msg
          end
        rescue => e
          flash[:error] = e.to_s
        end
      end
    end
    handle_failure_or_success(root_path) do
      @symbols
    end
  end

  # pre :signed_in do signed_in? end
  def period_types
    if @period_types.nil? then
      @period_types = current_user.mas_session.period_types
      if @period_types.nil? then
        begin
          symbols = symbol_list(true)
          if symbols != nil && symbols.length > 0 && ! flash[:error] then
            do_mas_request do
              mas_client.request_period_types(symbols.first)
              mas_client.communication_failed
            end
            if @error_msg.nil? then
              if mas_client.communication_failed then
                flash[:error] = mas_client.last_exception.to_s
              else
                @period_types = mas_client.period_types
                current_user.mas_session.period_types = @period_types
                current_user.mas_session.save
              end
            else
              flash[:error] = @error_msg
            end
          end
        rescue => e
          flash[:error] = e.to_s
        end
      end
    end
    handle_failure_or_success(root_path) do
      @period_types
    end
  end

  # pre  :signed_in do signed_in? end
  # post :result_not_nil do |result| result != nil && result.class == Array end
  # type :out => Array
#!!!!!oldoldold!!!!!!
  def oldold____symbol_list(no_save = false)
    if @symbols.nil? then
      if current_user.mas_session != nil then
        @symbols = current_user.mas_session.symbols
      end
      if @symbols.nil? then
        client = mas_client
        client.request_symbols
        @symbols = client.symbols
        if current_user.mas_session != nil then
          current_user.mas_session.symbols = @symbols
          if ! no_save then
            current_user.mas_session.save
          end
        end
      end
    end
    @symbols
  end

  def period_type_start_year
    Rails.configuration.earliest_year
  end

  def period_type_end_year
    Rails.configuration.latest_year
  end

  def number_of_available_ports
    MasClientTools::number_of_available_ports
  end

  protected

  ###  Basic operations

  # !!!!...(... @error_msg is set to an error description)
  # !!!!TO-DO: Supply documentation!!!!
  def do_mas_request
    @error_msg = nil
    while yield && @error_msg.nil? do
      # For next yield, recreate @mas_client, connected via the "next port"
      mas_client(request_next_port: true)
    end
  end

  # If flash[:error], redirect to 'target_path', else execute (yield) the
  # supplied block of code.
  def handle_failure_or_success(target_path)
    if flash[:error] then
      redirect_to target_path
    else
      yield
    end
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
    if not signed_in? then
      deny_access
    end
  end

end
