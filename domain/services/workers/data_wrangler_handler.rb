# Managers of EODDataWrangler object, allowing EOD data retrieval to occur
# in a separate child process - Example:
#   handler = DataWranglerHandler.new(service_tag, log)
#   wrangler = EODDataWrangler.new(...)
#   ...
#   handler.async.execute(wrangler)
#!!!!???Can this class be generalized to also handle EOD-data-ready ->
#!!!!!!!EventBasedTrigger processing?
class DataWranglerHandler
  include Concurrent::Async, Contracts::DSL, TatServicesFacilities

  public

  #####  State-changing operations

  # Perform data polling/retrieval by calling 'wrangler.execute' within a
  # forked child process.  Note: Invoke this method via 'async' - e.g.:
  #   handler.async.execute(wrangler)
  def execute(wrangler)
    tries = 0
    loop do
      child = fork do
        wrangler.execute(@child_error_key, RETRY_TAG)
      end
      tries += 1
      status = Process.wait(child)
      if tries > RETRY_LIMIT then
        warn("#{@tag}: Retry limit reached (#{RETRY_LIMIT}) - aborting...")
        break
      end
      error_msg = retrieved_message(@child_error_key)
      if error_msg != nil then
        delete_message(@child_error_key)
        warn("#{@tag}: #{error_msg}")
        if error_msg[0..RETRY_TAG.length-1] == RETRY_TAG then
          warn("Retrying #{@tag} (for #{wrangler.inspect})")
        else
          error("#{@tag}: Unrecoverable error")
          # Unrecoverable error - end loop.
          break
        end
      else
        info("#{@tag}: succeeded (#{wrangler.inspect})")
        # error_msg.nil? implies success, end the loop.
        break
      end
      sleep RETRY_PAUSE
    end
  end

  private

  ##### Implementation

  RETRY_PAUSE, RETRY_MINUTES_LIMIT = 15, 210
  RETRY_LIMIT = (RETRY_MINUTES_LIMIT * 60) / RETRY_PAUSE
  RETRY_TAG = 'retry'

  pre :good_args do |tg, lg| ! (tg.nil? || lg.nil?) end
  def initialize(svc_tag, the_log)
    @log = the_log
    @child_error_key = new_semi_random_key(svc_tag.to_s)
    @tag = svc_tag
    # Async initialization:
    super()
  end

  def log_msg(s)
    error_log.warn(s)
  end

end
