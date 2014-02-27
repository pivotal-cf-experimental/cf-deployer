require 'cf_deployer/shell_out'

module CfDeployer
  class Logger
    def initialize
      @columns = ShellOut.capture_output('tput cols').to_i
    end

    def log_message(message)
      puts colored(:green, :black, line_with_timestamp("# #{message}"))
    end

    def log_execution(command)
      puts colored(:yellow, :black, line_with_timestamp("(#{command})"))
    end

    def log_exception(exception)
      $stderr.puts colored(:magenta, :black, line_with_timestamp("error: #{exception.message}"))

      return unless exception.backtrace

      exception.backtrace.each do |location|
        $stderr.puts colored(:red, :black, line_with_timestamp("  `- #{location}"))
      end
    end

    private

    COLOR_CODES = {
      :black => 0,
      :red => 1,
      :green => 2,
      :yellow => 3,
      :blue => 4,
      :magenta => 5,
      :cyan => 6,
      :white => 7
    }

    def colored(fg, bg, line)
      "\e[4#{COLOR_CODES[bg]};3#{COLOR_CODES[fg]}m#{line}\e[0m"
    end

    def line_with_timestamp(message)
      time = timestamp
      line = message.ljust(@columns - time.size - 4)
      "#{line}    #{time}"
    end

    def timestamp
      "# #{Time.now}"
    end
  end
end