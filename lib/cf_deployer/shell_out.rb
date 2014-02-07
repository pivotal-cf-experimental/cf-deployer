module CfDeployer
  module ShellOut
    def self.capture_output(command)
      `#{command}`
    end
  end
end
