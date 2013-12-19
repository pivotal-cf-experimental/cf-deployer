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
        let(:pid) { 'fake-pid' }
        let(:options) do
          {out: @cmd_stdout}
        end

        subject(:runner) { SpawnAndWait.new(logger, spawner) }

        before do
          allow(spawner).to receive(:spawn).and_return(pid)
          allow(Process).to receive(:wait)
        end

        it "logs the execution" do
          run "ls"

          expect(logger).to have_logged("ls")
        end

        it "spawns the command and waits for it to complete" do
          run "echo 'hello,\n world!'"

          expect(spawner).to have_received(:spawn).with("echo 'hello,\n world!'", options)
          expect(Process).to have_received(:wait).with(pid)
        end

        context "when the command fails" do
          it "raises an error and print the standard error" do
            expect(Process).to receive(:wait).and_return do
              system('fail')
            end

            expect {
              run "notacommand 2>/dev/null"
            }.to raise_error(RuntimeError, /command failed.*notacommand/i)
          end
        end
      end
    end
  end
end
