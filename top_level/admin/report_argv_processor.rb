require 'optparse'

# Processing of command-line arguments for TAT report analysis
class ReportArgvProcessor
  include Contracts::DSL

  public

  # The input file, opened for reading, as specified on the command line
  attr_reader :input_file

  private

  pre  :filepath do @options[:input] != nil end
  post :ifile do self.input_file != nil end
  def open_input_file
    filepath = @options[:input]
    @input_file = File.new(filepath, "r")
  end

  def process_cl_args
    @options = {}
    OptionParser.new do |parser|
      parser.on("-i", "--input=filepath",
                "retrieve report data from 'filepath'") do |f|
        @options[:input] = f
      end
    end.parse!
    if ! @options[:input] then
      raise "Expected file-path argument not provided"
    end
    open_input_file
  end

  attr_reader :config, :name

  pre :config do |cfg| cfg != nil end
  def initialize(cfg, name = nil)
    @config = cfg
    @name = name
    process_cl_args
  end

end
