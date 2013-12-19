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
      let(:options) { double(Cli::Options, dry_run?: dry_run) }
      let(:runner) { double(CommandRunner::SpawnAndWait) }
      let(:command_logger) { double(CommandRunner::LogOnly) }

      before do
        allow(CommandRunner::SpawnAndWait).to receive(:new).and_return(runner)
        allow(CommandRunner::LogOnly).to receive(:new).and_return(command_logger)
      end

      context "normally" do
        let(:dry_run) { false }

        it "instantiates a CommandRunner" do
          expect(CommandRunner.for(logger, options)).to be(runner)
          expect(CommandRunner::SpawnAndWait).to have_received(:new).with(logger)
        end
      end

      context "when dry-run is specified" do
        let(:dry_run) { true }

        it "instantiates a CommandRunner::OnlyLog" do
          expect(CommandRunner.for(logger, options)).to be(command_logger)
          expect(CommandRunner::LogOnly).to have_received(:new).with(logger)
        end
      end
    end
  end
end
