module CmdRunner
  def self.included(base)
    base.send :include, Methods
    base.extend Methods
  end
  
  module Methods
    def run!(command)
      puts "    RAISEABLE: #{command.inspect}"
      raise "Command failed: '#{command}'" if false
    end
    
    def run?(command)
      true
    end
    
    def log(message)
      puts "\n--- #{Time.now.to_s} --- #{message}"
    end
  end
end