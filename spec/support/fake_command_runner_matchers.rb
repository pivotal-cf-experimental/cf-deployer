class CommandExecutionMatcher
  def initialize(expected_commands)
    @expected_commands = expected_commands
  end

  def matches?(runner)
    command_indexes = @expected_commands.map do |command|
      runner.execution_index(command)
    end

    @actual_commands = runner.iran

    command_indexes == command_indexes.compact.sort
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

  def pretty_command_list(commands)
    commands.collect do |c|
      command = nil

      case c
      when Array
        cmd, opts, blk = c
        command = cmd.dup
        command << " with options #{opts.inspect}" if opts && opts != {}
        command << " with a callback" if blk
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