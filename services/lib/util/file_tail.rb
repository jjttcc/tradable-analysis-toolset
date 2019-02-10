# Simple utility class to provide the last <n> lines of a file
# (Borrowed from molf on stackoverflow:
# https://stackoverflow.com/questions/3024372/how-to-read-a-file-from-bottom-to-top-in-ruby)
class FileTail
  include Contracts::DSL

  public

  attr_reader :filepath

  # The last 'n' lines of 'filepath' - nil if 'filepath' does not exist or
  # if the file is empty
  pre  :n_sane do |n| n != nil && n.is_a?(Integer) && n > 0 end
  post :is_array do |result| implies(result != nil, result.class == Array) end
  def last_n_lines(n)
    tail_buf_ln = TAIL_BUF_LENGTH
    result = nil
    if FileTest.exist?(filepath) then
      file = File.open(filepath, 'r')
      if file.size > 0 then
      if tail_buf_ln > file.size then
        tail_buf_ln = file.size / 2
      end
      file.seek -tail_buf_ln, IO::SEEK_END
      buf = ""
      while buf.count("\n") <= n do
        buf = file.read(tail_buf_ln) + buf
        file.seek 2 * -tail_buf_ln, IO::SEEK_CUR
      end
      result = buf.split("\n")[-n..-1]
      end
    end
    result
  rescue Errno::EINVAL => e
    return last_n_lines_alt(n)
  rescue StandardError => e
    $log.error("#{self.class}.#{__method__}: #{e}")
  end

  private

  TAIL_BUF_LENGTH = 65536

  def initialize(filepath)
    @filepath = filepath
  end

  def last_n_lines_alt(n)
    result = []
    lines = File.readlines(filepath)
    if lines.count > 0 then
      result = [lines.last]
    end
    result
  end

end
