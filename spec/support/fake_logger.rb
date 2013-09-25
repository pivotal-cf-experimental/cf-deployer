module CfDeployer
  class FakeLogger
    attr_reader :logged

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
      @logged.any? { |logged_entry| entry === logged_entry }
    end
  end
end