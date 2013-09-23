require "spec_helper"

describe CmdRunner do
  before { $env = {} }
  subject(:runner) { Class.new { include CmdRunner } }

  it "runs a command" do
    capture_std do |stdout, stderr, _|
      runner.real_run! "echo 'hello,\n world!'"

      expect(stdout).to eq("hello,\n world!\n")
      expect(stderr).to be_empty
    end
  end

  it "captures the env variables" do
    expect {
      capture_std do |stdout, _, _|
        runner.real_run! "export FOO=bar; echo $FOO"

        expect(stdout).to include("bar")
      end
    }.to change { $env["FOO"] }.from(nil).to("bar")

  end

  it "persists the env variables between tests" do
    runner.real_run! "export FOO=bar"
    capture_std do |stdout, _, _|
      runner.real_run! "echo $FOO"
      expect(stdout).to eql("bar\n")
    end
  end

  xit "reads standard input" do
    capture_std do |stdout, _, stdin|
      stdin.write("dog\n")
      stdin.rewind
      runner.real_run! "read CAT; echo $CAT"
      expect(stdout).to eq "dog\n"
    end
  end

  context "when the command fails" do
    it "raises an error and print the standard error" do
      capture_std do |_, stderr, _|
        expect {
          runner.real_run! "notacommand"
        }.to raise_error(RuntimeError, /command failed.*notacommand/i)
        expect(stderr).to match(/command not found/i)
      end
    end
  end
end