SRVC_AR_PATH = '../../../services/lib/architectural/active_record'
require_relative "#{SRVC_AR_PATH}/forked_database_execution"

class DBForkTest
  include Contracts::DSL, ForkedDatabaseExecution

  public

  attr_accessor :stop_child

  private

  def initialize
    @stop_child = false
  end

end

LASTSLEEP = 5
WAITSLEEP = 6
NOWAITSLEEP = 10
WAITKILLSLEEP = 6
INCHILDSLEEP = 0.75

def do_some_db_stuff
  ts = EventBasedTrigger.all
  puts "found #{ts.count} triggers"
  ts = TradableSymbol.all
  puts "found #{ts.count} symbols"
  s = SymbolListAssignment.all
  puts "found #{s.count} slas"
  sls = SymbolList.all
  puts "found #{sls.count} sls"
  u = User.all
  puts "found #{u.count} user"
end

def do_db_fork_test(wait)
  command = DBForkTest.new
  if wait then
    cmd = command.method(:execute_with_wait)
  else
    cmd = command.method(:execute_without_wait)
  end
  handlers = {TERM: lambda { command.stop_child = true} }
  size=1250000
  puts "parent: #{$$}"
  if wait then
    wait_thread = Thread.new do
      puts "sleeping #{WAITKILLSLEEP}"
      sleep WAITKILLSLEEP
      puts "woke up - trying to kill #{command.child_pid}"
      Process.kill(:TERM, command.child_pid)
    end
  end
  cmd.call(handlers) do
    puts "child: #{$$}"
    s = []
    do_some_db_stuff
    while ! command.stop_child do
      s << Random.new.bytes(size)
      sleep INCHILDSLEEP
    end
  end
  if wait then
    secs = WAITSLEEP
    no = ''
    wait_thread.join
    puts "the child was #{command.child_pid}"
  else
    secs = NOWAITSLEEP
    no = 'NOT '
    puts "the child is #{command.child_pid}"
    puts "CLOSING DB connection."
  end
  puts "#{no}waiting (I am parent: #{$$})"
  puts "sleeping #{secs}"
  sleep secs
  puts "OPENING DB connection."
  if ! wait then
    puts "sleeping #{secs} (I am parent: #{$$})"
    sleep LASTSLEEP
    Process.kill(:TERM, command.child_pid)
  end
end

desc 'DB fork test!'
task test_db_fork: :environment do
  puts "test_db_fork"
  puts "rails env: #{ENV['RAILS_ENV']}"
  puts "test with wait..."
  do_db_fork_test(true)
  puts "test without wait..."
  do_db_fork_test(false)
end
