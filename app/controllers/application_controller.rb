class ApplicationController < ActionController::Base
  public

  protect_from_forgery
  include SessionsHelper, ControllerErrorHandling
  # NOTE: Using Contracts::DSL in test and development causes problems in
  # this class; therefore, it is not used - pre and post are within comments.

  helper_method :mas_client, :symbol_list, :period_types,
    :period_type_start_year, :period_type_end_year

  before_action :set_locale

  public

  def index
    @motd = MOTD.new
  end

  public ###  Access

  # MasClient object for the current user
  # If connection attempt to the server fails, RuntimeError is raised.
  # If 'request_next_port' and no more ports are available, MasNoMorePorts is
  # raised.
  # pre :signed_in do signed_in? end
  # post :result do |result| ! result.nil? end
  def mas_client(request_next_port: false)
    begin
      if @mas_client.nil? || request_next_port then
        @mas_client = MasClientTools::mas_client(user: current_user,
                                                next_port: request_next_port)
      end
    rescue MasNoMorePorts => e
      raise MasNoMorePorts.new("Connection to MAS server failed: #{e.inspect}")
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
        rescue => e
          flash[:error] = e.to_s
          register_exception(e)
        end
        handle_mas_client_error(redirect_ok: false)
      end
    end
    @symbols
  end

  # pre :signed_in do signed_in? end
  # post :result do @period_types != nil end
  def period_types
    if @period_types.nil? then
      @period_types = current_user.mas_session.period_types
      if @period_types.nil? then
        begin
          @period_types = []
          symbols = symbol_list(true)
#!!!fix: ! flash[:error]:
          if symbols != nil && symbols.length > 0 && ! flash[:error] then
            do_mas_request do
              mas_client.request_period_types(symbols.first)
              mas_client.communication_failed
            end
            if mas_client.communication_failed then
              flash[:error] = mas_client.last_exception.to_s
            else
              @period_types = mas_client.period_types
              current_user.mas_session.period_types = @period_types
              current_user.mas_session.save
            end
          end
        rescue => e
          flash[:error] = e.to_s
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

  def number_of_available_ports
    MasClientTools::number_of_available_ports
  end

  protected ###  Basic operations

  # Execute the passed-in block (via 'yield') - expected to be a
  # "mas_client.request_..." call.  If the block returns true (which
  # indicates that the block's MAS-server request has failed), force a
  # reconnection to the next socket port.  Continue this process until the
  # block returns false or we run out of ports.
  def do_mas_request
    while yield do
      # For next yield, recreate @mas_client, connected via the "next port"
      mas_client(request_next_port: true)
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

  protected ###  Locale

  def set_locale
    locale = params[:locale].to_s.strip.to_sym
    I18n.locale = I18n.available_locales.include?(locale) ? locale :
      I18n.default_locale
  end

  def default_url_options(options={})
    { locale: I18n.locale }
  end

end
