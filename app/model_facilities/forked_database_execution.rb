# Provides for execution, with a new database connection, of a specified code
# block in a (forked) child process.
# (The 'remove_connection', 'establish_connection' strategy came from:
# https://stackoverflow.com/questions/22012943/activerecordstatementinvalid-runtimeerror-the-connection-cannot-be-reused-in
# )
module ForkedDatabaseExecution
  include Contracts::DSL

  public

  #####  Access

  # child process id - available in the parent process
  attr_reader :child_pid

  #####  State-changing operations

  # Fork a child process and execute the specified block in the child
  # process.  In the parent, 'wait' for the child to terminate.
  # In the child, open a new connection in order to not interfere with the
  # parent's connection.  If 'sig_handlers' is not nil, it is used to specify
  # a Hash of: signal => code, so that, for each signal, s, in
  # sig_handlers, signal handler sig_handlers[s] is installed.
  # Note: The database connection is re-established in the parent (i.e.,
  # ActiveRecord::Base.establish_connection(...)) unless
  # @do_not_re_establish_connection is defined and evaluates to true.
  def execute_with_wait(sig_handlers = nil, &block)
    perform_execution(true, sig_handlers, block)
  end

  # Fork a child process and execute the specified block in the child
  # process.  In the parent, do not wait for the child to terminate.
  # In the child, open a new connection in order to not interfere with the
  # parent's connection.  If 'sig_handlers' is not nil, it is used to specify
  # a Hash of: signal => code, so that, for each signal, s, in
  # sig_handlers, signal handler sig_handlers[s] is installed.
  # Note: The database connection is re-established in the parent (i.e.,
  # ActiveRecord::Base.establish_connection(...)) unless
  # @do_not_re_establish_connection is defined and evaluates to true.
  def execute_without_wait(sig_handlers = nil, &block)
    perform_execution(false, sig_handlers, block)
  end

  protected ### Implementation

  pre :exists do |sig_handlers| ! sig_handlers.nil? end
  type in: Hash
  def trap_signals(sig_handlers)
    sig_handlers.keys.each do |sig|
      Signal.trap(sig) do
        sig_handlers[sig].call
      end
    end
  end

  private   ### Implementation

  def perform_execution(wait, sig_handlers = nil, block)
    @db_config = ActiveRecord::Base.remove_connection
    @child_pid = fork do
      if sig_handlers != nil then
        trap_signals(sig_handlers)
      end
      # Establish new db connection in forked child
      ActiveRecord::Base.establish_connection(@db_config)
      block.call
    end
    if ! @do_not_re_establish_connection then
      # Re-establish db connection in parent.
      ActiveRecord::Base.establish_connection(@db_config)
    end
    if wait then
      Process.wait(@child_pid)
    else
      Process.detach(@child_pid)
    end
  end

end
