require 'cf_deployer/logger'
require 'cf_deployer/cf_deploy'
require 'cf_deployer/options_parser'

module CfDeployer
  class CLI
    def self.start(argv, logger = CfDeployer::Logger.new)
      options_parser = OptionsParser.new(argv)
      options_parser.parse!
      options_parser.validate!

      cf_deploy = CfDeployer::CfDeploy.build(options_parser.options, logger)

      yield cf_deploy
    rescue => e
      logger.log_exception(e)
      exit 1
    end
  end
end
