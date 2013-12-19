require 'spec_helper'
require 'cf_deployer/command_runner'
#require 'cf_deployer/command_runner/spawn_and_wait'

module CfDeployer
  module CommandRunner
    describe SpawnAndWait do
      let(:logger) { FakeLogger.new }

      before { @cmd_stdout, @cmd_stdin = runner_pipe }

      def run(command, options = {}, &blk)
        runner.run!(command, options.merge(out: @cmd_stdout, in: @cmd_stdin), &blk)
      end

      describe "#run!" do
        subject(:runner) { CommandRunner.bash_runner(logger) }

        it "runs a command" do
          run "echo 'hello,\n world!'"
          expect(output).to say("hello,\n world!\n")
        end

        context "when given environment variables" do
          it "executes the command without the caller's environment" do
            run("echo ${FOO:-nope}", environment: {"FOO" => "bar"})
            expect(output).to say("bar")
          end

          it "does not pollute the caller's environment" do
            expect {
              run("echo $FOO", environment: {"FOO" => "bar"})
            }.to_not change { ENV["FOO"] }.from(nil)
          end
        end

        it "reads standard input" do
          run "read CAT; echo $CAT" do
            stdin.puts "dog"
          end

          expect(output).to say("dog")
        end

        context "when the command fails" do
          it "raises an error and print the standard error" do
            expect {
              run "notacommand 2>/dev/null"
            }.to raise_error(RuntimeError, /command failed.*notacommand/i)
          end
        end

        it "logs the execution" do
          run "ls"
          expect(logger).to have_logged("ls")
        end
      end
    end
  end
end
