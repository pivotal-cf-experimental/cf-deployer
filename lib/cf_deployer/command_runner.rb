class CommandRunner
  class CommandFailed < RuntimeError; end

  def run!(command, options = {})
    puts("\e[40;33m" + command.ljust(80) + "\e[0m")

    spawn_opts = options.dup

    env = spawn_opts.delete(:environment) || {}

    pid =
      begin
        Process.spawn(env, command, spawn_opts)
      rescue => e
        raise CommandFailed, "Spawning command failed: #{e.message}\n#{e.backtrace}"
      end

    yield if block_given?

    Process.wait(pid)

    raise CommandFailed, "Command failed: #{command.inspect} (options: #{options.inspect})" unless $?.success?
  end
end
