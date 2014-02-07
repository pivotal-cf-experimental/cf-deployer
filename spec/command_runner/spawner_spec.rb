require 'spec_helper'
require 'cf_deployer/command_runner/spawner'

module CfDeployer
  class CommandRunner
    describe Spawner do
      let(:logger) { FakeLogger.new }
      before do
        Process.unstub(:spawn)
        @cmd_stdout, @cmd_stdin = runner_pipe
      end

      describe "#spawn & #wait" do
        def spawn_and_wait(command, options={})
          runner = Spawner.new(command, options.merge(in: @cmd_stdin, out: @cmd_stdout))
          runner.spawn
          yield if block_given?
          runner.wait
        end

        it "runs a command" do
          spawn_and_wait "echo 'hello,\n world!'"
          expect(output).to say("hello,\n world!\n")
        end

        context "when given environment variables" do
          it "executes the command without the caller's environment" do
            spawn_and_wait("echo ${FOO:-nope}", environment: {"FOO" => "bar"})
            expect(output).to say("bar")
          end

          it "does not pollute the caller's environment" do
            expect {
              spawn_and_wait("echo $FOO", environment: {"FOO" => "bar"})
            }.to_not change { ENV["FOO"] }.from(nil)
          end
        end

        it "reads standard input" do
          spawn_and_wait "read CAT; echo $CAT" do
            stdin.puts "dog"
          end

          expect(output).to say("dog")
        end

        context "when the command fails" do
          it "raises an error and print the standard error" do
            expect {
              spawn_and_wait "notacommand 2>/dev/null"
            }.to raise_error(RuntimeError, /command failed.*notacommand/i)
          end
        end
      end
    end
  end
end
