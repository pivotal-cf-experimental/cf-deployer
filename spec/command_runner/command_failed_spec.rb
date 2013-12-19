require 'spec_helper'
require 'cf_deployer/command_runner/command_failed'

module CfDeployer::CommandRunner
  describe CommandFailed do
    it { expect(subject).to be_a(RuntimeError) }
  end
end
