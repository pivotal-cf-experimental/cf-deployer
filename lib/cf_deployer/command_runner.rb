require "cf_deployer/command_runner/spawn_only"
require "cf_deployer/command_runner/spawn_and_wait"
require "cf_deployer/command_runner/log_only"

module CfDeployer
  module CommandRunner
    def self.for(logger,dry_run)
      SpawnAndWait.new(logger, dry_run)
    end
  end
end
