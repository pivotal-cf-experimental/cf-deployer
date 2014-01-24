module CliMatchers
  RSpec::Matchers.define :validate_successfully do
    match do |cli|
      cli.parse!
      cli.validate!
      true
    end
  end

  RSpec::Matchers.define :fail_validation do |message|
    match do |cli|
      cli.parse!
      begin
        cli.validate!
      rescue described_class::OptionError => e
        @err = e
      end

      @err.to_s.match(message)
    end

    failure_message_for_should do |cli|
      if @err.nil?
        "Expected failure message matching #{message}, but got nothing"
      else
        "Expected failure message matching #{message}, got:\n#{@err.to_s}"
      end
    end
  end
end