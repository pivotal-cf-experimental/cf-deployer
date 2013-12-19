require "cf_deployer/command_runner/command_failed"

module CfDeployer
  module CommandRunner
    class SpawnOnly
      def initialize(*shell_args)
        @shell_args = shell_args
      end

      def spawn(command, spawn_opts)
        env = spawn_opts.delete(:environment) || {}

        Process.spawn(env, *@shell_args, command, spawn_opts)
      rescue => e
        raise CommandFailed, "Spawning command failed: #{e.message}\n#{e.backtrace}"
      end
    end
  end
end
