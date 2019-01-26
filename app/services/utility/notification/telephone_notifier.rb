class TelephoneNotifier < Notifier
  def perform_execution(notification_source)
    puts "stub!!!: #{self}.perform_execution"
@execution_succeeded = true #!!!stub!!!
notifications.each do |n| n.sent! end          #!!!stub!!!
# or delivered! or failed!!!!!!!!!!!!!!
  end
end
