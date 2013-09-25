module CfDeployer
  class FakeLogger
    def initialize
      @logged = []
    end

    def log_message(message)
      @logged << message
    end

    def log_execution(command)
      @logged << command
    end

    def has_logged?(entry)
      @logged.include?(entry)
    end
  end
end