require "cf_deployer/command_runner/command_failed"

module CfDeployer
  class CommandRunner
    class SpawnOnly
      def initialize(command, options)
        @command = command
        @options = options
        @env = @options.delete(:environment) || {}
      end

      def spawn
        @pid = Process.spawn(@env, "bash", "-c", @command, @options)
      rescue => e
        raise CommandFailed, "Spawning command failed: #{e.message}\n#{e.backtrace}"
      end

      def wait
        Process.wait(@pid)

        raise CommandFailed, "Command failed: #{@command.inspect} (options: #{@options.inspect})" unless $?.success?
      end
    end
  end
end
