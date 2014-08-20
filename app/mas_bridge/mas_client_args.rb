
# Abstraction of MasClient initialization arguments
class MasClientArgs

  public

  def initialize(user: nil, period_type_specs: nil)
    if user then hashtable[:user] = user end
    if period_type_specs
      hashtable[:period_type_specs] = period_type_specs
    end
  end

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

  private

  attr_reader :period_type_spec_wrappers

  def hashtable
    if @hashtable.nil?
      @hashtable = {
        host: Rails.configuration.mas_host,
        port: Rails.configuration.mas_port,
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
