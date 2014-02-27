class CommandExecutionMatcher
  def initialize(expected_commands)
    @expected_commands = expected_commands
  end

  def matches?(runner)
    @actual_commands = runner.iran

    ranges_with_initial_match = @actual_commands.each_with_index.map do |actual, i|
      i...(i+@expected_commands.length) if runner.command_matches?(@expected_commands[0], actual)
    end.compact

    ranges_with_initial_match.any? { |range| match_range(runner, @expected_commands, @actual_commands, range) }
  end

  def failure_message
    <<MSG
Expected to have executed:
#{pretty_command_list(@expected_commands)}

in order, but actually ran:
#{pretty_command_list(@actual_commands)}
MSG
  end

  def negative_failure_message
    <<MSG
Expected to NOT execute:
#{pretty_command_list(@expected_commands)}

but it did
MSG
  end

  private

  def match_range(runner, expected_commands, actual_commands, range)
    expected_commands.zip(actual_commands[range]).all? do |expected, actual|
      runner.command_matches?(expected, actual)
    end
  end

  def pretty_command_list(commands)
    commands.collect do |c|
      command = nil

      case c
      when Array
        cmd, opts, blk = c
        command = cmd.respond_to?(:<<) ? cmd.dup : cmd.inspect
        command << " with options #{opts.inspect}" if opts && opts != {}
        command << ' with a callback' if blk
      when String
        command = c
      when Regexp
        command = "a command matching #{c}"
      else
        command = "I DUNO LOL #{c}" # ¯\(°_o)/¯
      end

      "\t#{command}"
    end.join("\n")
  end
end

module FakeCommandRunnerMatchers
  def have_executed_serially(*commands)
    CommandExecutionMatcher.new(commands)
  end
end
