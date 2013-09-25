class FakeCommandRunner
  attr_reader :iran

  def initialize
    @iran = []
    @callbacks = []
  end

  def when_running(pattern, &blk)
    @callbacks << [pattern, blk]
  end

  def run!(command, options={}, &blk)
    execution = [command, options, blk]

    @iran << execution

    @callbacks.each do |pattern, callback|
      if command_matches?(pattern, execution)
        callback.call
      end
    end
  end

  def execution_index(command)
    @iran.index do |execution|
      command_matches?(command, execution)
    end
  end

  def command_matches?(command, actual)
    actual_command, actual_options, _ = actual

    case command
    when Array
      expected_command, expected_options, _ = command

      expected_command === actual_command && \
        expected_options === actual_options
    else
      command === actual_command
    end
  end
end