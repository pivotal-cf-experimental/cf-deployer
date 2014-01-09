require "spec_helper"
require "timecop"

require "cf_deployer/logger"

describe CfDeployer::Logger do
  around { |example| Timecop.freeze(&example) }

  subject { described_class.new(80) }

  def capture_log(type, *args)
    capture_output { subject.send(:"log_#{type}", *args) }
  end

  describe "#log_message" do
    before { capture_log(:message, "Hello, world!") }

    it "prints the message as a comment" do
      expect(output).to say("# Hello, world!")
    end

    it "pads the line to the terminal's width" do
      expect(output).to say(/^.{80}$/)
    end

    it "prints the timestamp on the right" do
      output.read_to_end
      expect(output.output).to match(/# #{Time.now}\n?$/)
    end

    context "when the message is longer than the columns" do
      before { capture_log(:message, "x" * 90) }

      it "has padding between the message and the timestamp" do
        expect(output).to say(/x{90}    # #{Time.now}\n?$/)
      end
    end
  end

  describe "#log_execution" do
    before { capture_log(:execution, "ls") }

    it "prints the command in parentheses" do
      expect(output).to say("(ls)")
    end

    it "prints the timestamp as a comment on the right" do
      expect(output).to say(/# #{Time.now}\n?$/)
    end
  end

  describe "#log_exception" do
    let(:exception) do
      begin
        raise "oh no!"
      rescue => e
        e
      end
    end

    before { capture_log(:exception, exception) }

    it "prints the exception message and backtrace to stderr" do
      expect(error_output).to say("error: oh no!")

      exception.backtrace.each do |location|
        expect(error_output).to say("  `- #{location}")
      end
    end
  end
end
