module LocalTime
  protected

  # Local timezone, as a String (found via:
  # https://stackoverflow.com/questions/12445336/local-time-zone-in-ruby )
  def local_timezone
    result = `
      if [ -f /etc/timezone ]; then
        cat /etc/timezone
      elif [ -h /etc/localtime ]; then
        readlink /etc/localtime | sed "s@.*/usr/share/zoneinfo/@@"
      else
        checksum=\`md5sum /etc/localtime | cut -d' ' -f1\`
        find /usr/share/zoneinfo/ -type f -exec md5sum {} \\; |
          grep "^$checksum" | sed "s/.*\\/usr\\/share\\/zoneinfo\\///" |
          head -n 1
      fi`.chomp
    if result.nil? || result.empty? then
      raise "Olson time zone could not be determined"
    end
    return result
  end

  def local_time(datetime)
    if @timezone.nil? then
      @timezone = local_timezone
    end
    TimeUtil::local_time(@timezone, datetime)
  end

end
