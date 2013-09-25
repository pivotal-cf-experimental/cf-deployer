module CfDeployer
  class CommandRunner
    class CommandFailed < RuntimeError; end

    def initialize(logger)
      @logger = logger
    end

    def run!(command, options = {})
      @logger.log_execution(command)

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
end