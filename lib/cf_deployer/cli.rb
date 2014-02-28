require 'cf_deployer/logger'
require 'cf_deployer/release'
require 'cf_deployer/options_parser'

module CfDeployer
  class CLI
    def self.start(argv, commands=[], logger = CfDeployer::Logger.new)
      options_parser = OptionsParser.new(argv)
      options_parser.parse!
      options_parser.validate!

      release = CfDeployer::Release.build(options_parser.options, logger)
      commands.each {|command| release.send command}
    rescue => e
      logger.log_exception(e)
      exit 1
    end
  end
end
