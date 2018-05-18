module ControllerErrorHandling
  protected

  ###  Status report

  def no_error
    @last_error.nil?
  end

  ###  Basic operations

  # post :mas_client_set do ! @mas_client.nil? end
  def handle_mas_client_error(redirect_ok: true)
    @last_error = nil
    if @last_exception then
      @last_error = @last_exception.to_s
      flash[:error] = @last_error
    else
      if @mas_client then
        if ! @mas_client.last_error_msg.empty? then
          @last_error = @mas_client.last_error_msg
          flash[:error] = @last_error
        else
        end
      else
        raise RuntimeError.new("TAT system error: mas_client not set")
      end
    end
    if ! @last_error.nil? then
      if redirect_ok then
        redirect_to root_path
      end
      $log.warn(@last_error)
    end
#!!!!:
$log.debug("[hmce] last_error: #{@last_error.inspect}")
$log.debug("[hmce] stack: #{caller.join("\n")}")
  end

  def register_exception(e)
    if ! e.nil? then
      @last_exception = e
    end
  end

end
