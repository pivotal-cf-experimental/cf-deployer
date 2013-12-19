module CfDeployer
  module CommandRunner
    class CommandFailed < RuntimeError; end

    def self.bash_runner(logger)
      SpawnAndWait.new(logger, SpawnOnly.new('bash', '-c'))
    end

    def self.for(logger, options)
      options.dry_run?? LogOnly.new(logger) : bash_runner(logger)
    end

    class SpawnAndWait
      def initialize(logger, spawner)
        @logger = logger
        @spawner = spawner
      end

      def run!(command, options = {})
        @logger.log_execution(command)

        spawn_opts = options.dup

        env = spawn_opts.delete(:environment) || {}

        pid = @spawner.spawn(env, command, spawn_opts)

        yield if block_given?

        Process.wait(pid)

        raise CommandFailed, "Command failed: #{command.inspect} (options: #{options.inspect})" unless $?.success?
      end
    end

    class LogOnly
      def initialize(logger)
      end
    end

    class SpawnOnly
      def initialize(*shell_args)
        @shell_args = shell_args
      end

      def spawn(env, command, spawn_opts)
        Process.spawn(env, *@shell_args, command, spawn_opts)
      rescue => e
        raise CommandFailed, "Spawning command failed: #{e.message}\n#{e.backtrace}"
      end
    end
  end
end
