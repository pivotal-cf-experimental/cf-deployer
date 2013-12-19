require 'spec_helper'
require 'cf_deployer/command_runner/command_failed'

describe CfDeployer::CommandRunner::CommandFailed do
  it { expect(subject).to be_a(RuntimeError) }
end

