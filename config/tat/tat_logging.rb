
# If the TAT_LOGGING environment variable is set and if 'object' will
# respond to a :turn_on_logging method call, then call object.turn_on_logging.
# And if the TAT_VERBOSE environment variable is set and if 'object' will
# respond to a :verbose= method call, then call object.verbose = true.
def configure_logging(object)
  if object.respond_to?(:turn_on_logging) && ENV['TAT_LOGGING'] then
    object.turn_on_logging
puts "Logging is now on for #{object} (#{object.class})"
  end
  if object.respond_to?(:verbose=) && ENV['TAT_VERBOSE'] then
    object.verbose = true
puts "verbose is now set for #{object} (#{object.class})"
  end
end
