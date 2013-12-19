require 'spec_helper'
require 'cf_deployer/command_runner'
require 'cf_deployer/command_runner/spawn_only'

module CfDeployer
  describe CommandRunner do
    let(:logger) { FakeLogger.new }

    before { @cmd_stdout, @cmd_stdin = runner_pipe }

    def run(command, &blk)
      runner.run!(command, options, &blk)
    end

    describe "#run!" do
      let(:spawner) { double(CommandRunner::SpawnOnly) }
      let(:options) do
        {out: @cmd_stdout}
      end

      subject(:runner) { CommandRunner.new(logger, dry_run) }

      before do
        allow(CommandRunner::SpawnOnly).to receive(:new).and_return(spawner)
        allow(spawner).to receive(:spawn)
        allow(spawner).to receive(:wait)
      end

      context "when dry-run is set to true" do
        let(:dry_run) { true }

        it "does not spawn a command but logs it" do
          run "echo 'hello,\n world!'"

          expect(spawner).not_to have_received(:spawn)
          expect(logger).to have_logged("echo 'hello,\n world!'")
        end
      end

      context "when dry-run is set to false" do
        let(:dry_run) { false }

        it "logs then spawns and waits for the command" do
          expect(spawner).to receive(:spawn).ordered
          expect(spawner).to receive(:wait).ordered

          run "echo 'hello,\n world!'"

          expect(CommandRunner::SpawnOnly).to have_received(:new).with("echo 'hello,\n world!'", options)
          expect(logger).to have_logged("echo 'hello,\n world!'")
        end
      end
    end
  end
end
