
# Abstraction of MasClient initialization arguments
class MasClientArgs

  public

  def [](key)
    result = hashtable[key]
    if result.nil?
      hashtable.keys.each do |k|
        if k.to_s =~ /#{key}/
          result = hashtable[k]
        end
      end
    end
    if result.nil?
      user = hashtable[:user]
      case key
        when /period.*type/
          if user != nil
            # (Extract only long-term specs.)
            result = wrapped_pts_s(user.charting_specs)
          end
        when /mas.session/
          if user != nil
            result = user.mas_session
          end
      end
    end
    result
  end

  # Shift such that settings[:port] is the next port in the list of
  # configured ports.  Raise an exception if there are no more ports.
  def shift_to_next_port
    Rails.application.config.current_port_index += 1
    current_port = Rails.configuration.mas_ports[
      Rails.application.config.current_port_index]
    if current_port != nil then
      @hashtable[:port] = current_port
    else
      raise "No more ports available"
    end
  end

  # Perform a reset such that settings[:port] is the first port in the list of
  # configured ports.
  def reset_port
    Rails.application.config.current_port_index = 0
    current_port = Rails.configuration.mas_ports[
      Rails.application.config.current_port_index]
    @hashtable[:port] = current_port
  end

  def settings
    hashtable
  end

  private

  attr_reader :period_type_spec_wrappers

  def initialize(user: nil, period_type_specs: nil)
#!!!!!!NOTE: We might need a truly persistent alternative to Rails......:
    if !  Rails.application.config.respond_to? :current_port_index then
      Rails.application.config.current_port_index = 0
    end
    if user then hashtable[:user] = user end
    if period_type_specs then
      hashtable[:period_type_specs] = period_type_specs
    end
  end

  def hashtable
    if @hashtable.nil? then
      @hashtable = {
        host: Rails.configuration.mas_host,
        port: Rails.configuration.mas_ports[
          Rails.application.config.current_port_index],
        timeout: Rails.configuration.timeout_seconds,
        factory: TradableObjectFactory.new,
        close_after_w: false,
      }
    end
    @hashtable
  end

  # The array 'specs' (array of PeriodTypeSpec) wrapped in a set of
  # PeriodTypeSpecAdapter so that the MasClient accesses the adapter interface
  # instead of the real thing
  def wrapped_pts_s(specs)
     if @period_type_spec_wrappers.nil?
       @period_type_spec_wrappers = []
       specs.each do |s|
         @period_type_spec_wrappers << PeriodTypeSpecAdapter.new(s)
       end
     end
     @period_type_spec_wrappers
  end

end
