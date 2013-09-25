require "pty"
require "blue-shell"
require "stringio"

module CommandHelper
  attr_reader :stdout, :stderr, :stdin, :status

  def runner_pipe
    @stdout, cmd_stdout = PTY.open
    system("stty raw", :in => cmd_stdout)
    cmd_stdin, @stdin = IO.pipe

    [cmd_stdout, cmd_stdin]
  end

  def capture_output
    orig_out, orig_err = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    @stdout, @stderr = $stdout, $stderr
    yield
  ensure
    @stdout.rewind
    @stderr.rewind
    $stdout, $stderr = orig_out, orig_err
  end

  def output
    @output ||= BlueShell::BufferedReaderExpector.new(@stdout)
  end

  def error_output
    @error_output ||= BlueShell::BufferedReaderExpector.new(@stderr)
  end
end