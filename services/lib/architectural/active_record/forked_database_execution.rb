# Provides for execution, with a new database connection, of a specified code
# block in a (forked) child process.
# (The 'remove_connection', 'establish_connection' strategy came from:
# https://stackoverflow.com/questions/22012943/activerecordstatementinvalid-runtimeerror-the-connection-cannot-be-reused-in
# )
module ForkedDatabaseExecution
  include Contracts::DSL

  public

  # child process id - available in the parent process
  attr_reader :child_pid

  public  ###  Access

  def db_config
    if @db_config.nil? then
#      initialize
    end
    @db_config
  end

  public  ###  Basic operations

  # Fork a child process and execute the specified block in the child
  # process.  In the parent, 'wait' for the child to terminate.
  # In the child, open a new connection in order to not interfere with the
  # parent's connection.  If 'sig_handlers' is not nil, it is used to specify
  # a Hash of: signal => code, so that, for each signal, s, in
  # sig_handlers, signal handler sig_handlers[s] is installed.
  def execute_with_wait(sig_handlers = nil, &block)
    perform_execution(true, sig_handlers, block)
  end

  # Fork a child process and execute the specified block in the child
  # process.  In the parent, do not wait for the child to terminate.
  # In the child, open a new connection in order to not interfere with the
  # parent's connection.  If 'sig_handlers' is not nil, it is used to specify
  # a Hash of: signal => code, so that, for each signal, s, in
  # sig_handlers, signal handler sig_handlers[s] is installed.
  def execute_without_wait(sig_handlers = nil, &block)
    perform_execution(false, sig_handlers, block)
  end

  # Close the database connection, if it is open.
  def close_connection
    if ActiveRecord::Base.connected? then
      ActiveRecord::Base.remove_connection
    end
  end

  # Open the database connection, if it is closed.
  def open_connection
    if ! ActiveRecord::Base.connected? then
      ActiveRecord::Base.establish_connection(db_config)
    end
  end

  protected

  pre :exists do |sig_handlers| ! sig_handlers.nil? end
  type in: Hash
  def trap_signals(sig_handlers)
    sig_handlers.keys.each do |sig|
      Signal.trap(sig) do
        sig_handlers[sig].call
      end
    end
  end

  private

  def initialize
    @db_config = ActiveRecord::Base.connection_config
  end

  def perform_execution(wait, sig_handlers = nil, block)
#!!!dbconfig = ActiveRecord::Base.remove_connection
    ActiveRecord::Base.remove_connection
    @child_pid = fork do
      if sig_handlers != nil then
        trap_signals(sig_handlers)
      end
      # Establish new db connection in forked child
      ActiveRecord::Base.establish_connection(db_config)
      block.call
    end
    # Re-establish db connection in parent.
    ActiveRecord::Base.establish_connection(db_config)
    if wait then
      Process.wait(@child_pid)
    else
      Process.detach(@child_pid)
    end
  end

end
