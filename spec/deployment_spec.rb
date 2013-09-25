require "fileutils"

require "spec_helper"
require "cf_deployer/deployment"

describe Deployment do
  before do
    @deployments_path = Dir.mktmpdir("deployments")

    File.open(File.join(@deployments_path, "bosh_environment"), "w") do |io|
      io.write <<EOF
export FOO=1
export BAR=2
EOF
    end
  end

  after { FileUtils.rm_rf(@deployments_path) }

  subject { described_class.new(@deployments_path) }

  describe "#bosh_environment" do
    it "returns a hash of the environment variables" do
      expect(subject.bosh_environment).to eq("FOO" => "1", "BAR" => "2")
    end
  end
end