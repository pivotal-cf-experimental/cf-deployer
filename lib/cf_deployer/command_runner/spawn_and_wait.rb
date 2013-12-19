require "cf_deployer/command_runner/command_failed"

module CfDeployer
  module CommandRunner
    class SpawnAndWait
      def initialize(logger, spawner)
        @logger = logger
        @spawner = spawner
      end

      def run!(command, options = {})
        @logger.log_execution(command)

        spawn_opts = options.dup

        pid = @spawner.spawn(command, spawn_opts)

        yield if block_given?

        Process.wait(pid)

        raise CommandFailed, "Command failed: #{command.inspect} (options: #{options.inspect})" unless $?.success?
      end
    end
  end
end
