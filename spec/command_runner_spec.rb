require "spec_helper"
require "cf_deployer/command_runner"

describe CommandRunner do
  subject(:runner) { described_class.new }

  around { |example| capture_output(&example) }

  def run(command, options = {}, &blk)
    runner.run!(command, options.merge(out: @cmd_stdout, in: @cmd_stdin), &blk)
  end

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
        run "notacommand"
      }.to raise_error(RuntimeError, /command failed.*notacommand/i)
    end
  end
end