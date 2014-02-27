require 'dogapi'

require 'cf_deployer/hooks/hook'

module CfDeployer
  class DatadogEmitter < Hook
    def initialize(logger, dogapi, deployment)
      @logger = logger
      @dogapi = dogapi
      @deployment = deployment
    end

    def pre_deploy
      @logger.log_message "emitting start_deploy event for #{@deployment}"
      @dogapi.emit_event(deployment_event('start_deploy'))
    end

    def post_deploy
      @logger.log_message "emitting end_deploy event for #{@deployment}"
      @dogapi.emit_event(deployment_event('end_deploy'))
    end

    private

    def deployment_event(event)
      Dogapi::Event.new(event, tags: ["deployment:#{@deployment}"])
    end
  end
end
