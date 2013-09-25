require "pty"
require "blue-shell"

module CommandHelper
  attr_reader :stdout, :stderr, :stdin, :status

  def capture_output
    @stdout, @cmd_stdout = PTY.open
    system("stty raw", :in => @cmd_stdout)
    @cmd_stdin, @stdin = IO.pipe
    yield
  end

  def output
    @output ||= BlueShell::BufferedReaderExpector.new(stdout)
  end

  def error_output
    @error_output ||= BlueShell::BufferedReaderExpector.new(stderr)
  end
end