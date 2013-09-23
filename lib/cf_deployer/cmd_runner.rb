require "open3"

module CmdRunner
  def self.included(base)
    base.send :include, Methods
    base.extend Methods
  end

  module Methods
    def run!(command)
      if prompt_command(command)
        success = system command
        raise "Command failed: '#{command}'" unless success
      else
        puts "Skipping!"
      end
    end

    def run?(command)
      if prompt_command(command)
        system command
      else
        puts "Skipping!"
        false
      end
    end
    
    def log(message)
      puts "\n--- #{Time.now.to_s} --- #{message}"
    end

    private

    def prompt_command(command)
      puts "About to run: #{command.inspect}"
      print "Continue? (yes/no): "
      confirm
    end

    def confirm
      gets.chomp.tap { |x| p [:got, x] } =~ /^y/i
    end
  end
end
