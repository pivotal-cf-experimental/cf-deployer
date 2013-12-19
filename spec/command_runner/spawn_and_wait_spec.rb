require 'spec_helper'
require 'cf_deployer/command_runner/spawn_and_wait'
require 'cf_deployer/command_runner/spawn_only'

module CfDeployer
  module CommandRunner
    describe SpawnAndWait do
      let(:logger) { FakeLogger.new }

      before { @cmd_stdout, @cmd_stdin = runner_pipe }

      def run(command, &blk)
        runner.run!(command, options, &blk)
      end

      describe "#run!" do
        let(:spawner) { double(SpawnOnly) }
        let(:options) do
          {out: @cmd_stdout}
        end

        subject(:runner) { SpawnAndWait.new(logger) }

        before do
          allow(SpawnOnly).to receive(:new).and_return(spawner)
          allow(spawner).to receive(:spawn)
          allow(spawner).to receive(:wait)
        end

        it "logs the execution" do
          run "ls"

          expect(logger).to have_logged("ls")
        end

        it "spawns the command and waits for it to complete" do
          expect(spawner).to receive(:spawn).ordered
          expect(spawner).to receive(:wait).ordered

          run "echo 'hello,\n world!'"

          expect(SpawnOnly).to have_received(:new).with("echo 'hello,\n world!'", options)
        end
      end
    end
  end
end
