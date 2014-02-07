require 'cf_deployer/shell_out'

Dir.glob(File.expand_path("../support/*.rb", __FILE__)).each do |support|
  require support
end

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.include CommandHelper
  config.include FakeCommandRunnerMatchers
  config.include BlueShell::Matchers
  config.include CliMatchers

  config.before do
    Process.stub(:spawn).and_raise("It is unsafe to call Process.spawn in a spec")
    CfDeployer::ShellOut.stub(:capture_output).and_raise("It is unsafe to call ShellOut.capture_output in a spec")
  end
end
