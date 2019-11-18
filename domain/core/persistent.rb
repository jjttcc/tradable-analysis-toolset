# Objects that are persistent - e.g., are saved to a database
module Persistent
  include Contracts::DSL, TatUtil

  public

  #####  Access

  attr_accessor :log

  # The object's persistent fields
  post :exists do |result| result != nil end
  post :enumerable do |result| result.is_a?(Enumerable) end
  def fields
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # The object's associations to other objects.
  post :exists do |result| result != nil end
  post :enumerable do |result| result.is_a?(Enumerable) end
  def associations
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  #####  Status report

  def fields_exist
    fields.all? do |f|
      self.respond_to? f
    end
  end

  def associations_exist
    associations.all? do |a|
      self.respond_to? a
    end
  end

  def invariant
    fields_exist && associations_exist
  end

  protected

  #####  Implementation

  def log_message(tag, msg)
    if log.nil? then
      if $global_config != nil then
        self.log = $global_config.log
      else
        self.log = false    # i.e., no global log available
      end
    end
    if log == false then
      puts "#{tag}: #{msg}"
    else
      log.send_message(tag: tag, msg: msg)
    end
  end

end
