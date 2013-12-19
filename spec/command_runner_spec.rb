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
      let(:runner) { double(CommandRunner) }
      let(:command_logger) { double(CommandRunner::LogOnly) }

      before do
        allow(CommandRunner).to receive(:bash_runner).and_return(runner)
        allow(CommandRunner::LogOnly).to receive(:new).and_return(command_logger)
      end

      context "normally" do
        let(:dry_run) { false }

        it "instantiates a CommandRunner" do
          expect(CommandRunner.for(logger, options)).to be(runner)
          expect(CommandRunner).to have_received(:bash_runner).with(logger)
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

    describe "#run!" do
      subject(:runner) { described_class.bash_runner(logger) }

      it "runs a command" do
        run "echo 'hello,\n world!'"
        expect(output).to say("hello,\n world!\n")
      end

      context "when given environment variables" do
        it "executes the command without the caller's environment" do
          run("echo ${FOO:-nope}", environment: { "FOO" => "bar" })
          expect(output).to say("bar")
        end

        it "does not pollute the caller's environment" do
          expect {
            run("echo $FOO", environment: { "FOO" => "bar" })
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

    describe "using zsh" do
      subject(:runner) { CommandRunner::SpawnAndWait.new(logger, CommandRunner::SpawnOnly.new('zsh', '-c')) }

      it "allows the client to specify a shell" do
        expect { run('set -o pipefail 2>/dev/null') }.to raise_error(RuntimeError, /command failed/i)
      end
    end

    describe "using bash" do
      subject(:runner) { CommandRunner.bash_runner(logger) }

      it "allows the client to specify a shell" do
        run('set -o pipefail && echo "hi"')
        expect(output).to say("hi")
      end
    end
  end
end
