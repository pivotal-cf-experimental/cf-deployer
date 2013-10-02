require "fileutils"
require "yaml"

require "spec_helper"
require "cf_deployer/repo"

module CfDeployer
  describe Repo do
    let(:logger) { FakeLogger.new }
    let(:runner) { FakeCommandRunner.new }
    let(:repo_name) { "some-repo" }
    let(:ref) { "some-ref" }

    subject { described_class.new(logger, runner, @repos_path, repo_name, ref) }

    around do |example|
      Dir.mktmpdir("repos_path") do |release_repo|
        @repos_path = release_repo
        example.call
      end
    end

    def repo_path
      File.join(@repos_path, repo_name)
    end

    describe "#sync!" do
      context "when the repo does not exist" do
        it "clones into the repo path" do
          subject.sync!

          expect(runner).to have_executed_serially(
            "git clone git@github.com:cloudfoundry/some-repo.git #{repo_path}",
          )
        end

        it "logs that it's cloning" do
          subject.sync!
          expect(logger).to have_logged("cloudfoundry/some-repo: not found; cloning")
        end
      end

      context "when the repo is already cloned" do
        before { FileUtils.mkdir_p(repo_path) }

        it "does not clone the repo" do
          subject.sync!

          expect(runner).not_to have_executed_serially(
            /git clone/,
          )
        end
      end

      it "cleans the repository and fetches the latest from origin on the ref" do
        subject.sync!

        expect(runner).to have_executed_serially(
          "git clone git@github.com:cloudfoundry/some-repo.git #{repo_path}",
          "cd #{repo_path} && git reset --hard",
          "cd #{repo_path} && git clean --force -d",
          "cd #{repo_path} && git fetch",
          "cd #{repo_path} && git checkout some-ref",
          "cd #{repo_path} && git submodule update --init --recursive",
        )
      end

      it "logs that it's syncing" do
        subject.sync!
        expect(logger).to have_logged("cloudfoundry/some-repo: syncing with some-ref")
      end
    end
  end
end
