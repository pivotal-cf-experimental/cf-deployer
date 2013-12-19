require "spec_helper"
require "cf_deployer/command_runner"
require "cf_deployer/cli"

module CfDeployer
  describe CommandRunner do
    let(:logger) { FakeLogger.new }

    before { @cmd_stdout, @cmd_stdin = runner_pipe }

    def run(command, options = {}, &blk)
      runner.run!(command, options.merge(out: @cmd_stdout, in: @cmd_stdin), &blk)
    end

    describe ".for" do
      let(:runner) { double(CommandRunner::SpawnAndWait) }
      let(:command_logger) { double(CommandRunner::LogOnly) }

      before do
        allow(CommandRunner::SpawnAndWait).to receive(:new).and_return(runner)
        allow(CommandRunner::LogOnly).to receive(:new).and_return(command_logger)
      end

      it "instantiates a CommandRunner::SpawnAndWait" do
        expect(CommandRunner.for(logger, false)).to be(runner)
        expect(CommandRunner::SpawnAndWait).to have_received(:new).with(logger, false)
      end
    end
  end
end
