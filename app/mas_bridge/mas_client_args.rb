
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
            result = user.charting_specs
          end
        when /mas.session/
          if user != nil
            result = user.mas_session
          end
      end
    end
    result
  end

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

end
