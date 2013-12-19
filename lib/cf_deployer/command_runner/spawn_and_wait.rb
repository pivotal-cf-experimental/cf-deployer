module CfDeployer
  module CommandRunner
    class SpawnAndWait
      def initialize(logger, dry_run)
        @logger = logger
        @dry_run = dry_run
      end

      def run!(command, options = {})
        @logger.log_execution(command)

        unless @dry_run
          spawner = SpawnOnly.new(command, options)
          spawner.spawn
          spawner.wait
        end
      end
    end
  end
end
