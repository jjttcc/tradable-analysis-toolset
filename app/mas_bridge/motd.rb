class MOTD
  @@message = "Today is #{Time.new}"

  def message
    @@message
  end

end
