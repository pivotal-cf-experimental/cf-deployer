require 'cf_deployer/command_runner/spawner'

module CfDeployer
  class CommandRunner
    def initialize(logger, dry_run)
      @logger = logger
      @dry_run = dry_run
    end

    def run!(command, options = {})
      @logger.log_execution(command)

      unless @dry_run
        spawner = Spawner.new(command, options)
        spawner.spawn
        spawner.wait
      end
    end
  end
end
