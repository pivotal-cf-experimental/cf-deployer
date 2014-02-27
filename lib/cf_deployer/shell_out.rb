module CfDeployer
  module ShellOut
    def self.capture_output(command)
      `#{command}`
    end

    def self.with_clean_env(command)
      IO.popen ['bash', '-c', command, unsetenv_others: true]
    end
  end
end
