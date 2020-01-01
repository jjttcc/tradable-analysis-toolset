require_relative '../test_helper'

class EODRetrievalTest < MiniTest::Test
  def setup
    puts "tatdir: #{ENV['TATDIR']}"
    @script = "#{ENV['TATDIR']}/top_level/test/bin/eod-retrieval-test"
    @test_symbols = 'ibm f jcp dex kgc ups'
  end

  def test_one
    cmd = "#{@script} #{@test_symbols}"
    assert system(cmd)
  end
end
