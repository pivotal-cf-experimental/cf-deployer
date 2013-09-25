require "fileutils"
require "yaml"

require "spec_helper"
require "cf_deployer/release_repo"

module CfDeployer
  describe ReleaseRepo do
    let(:logger) { FakeLogger.new }
    let(:runner) { FakeCommandRunner.new }
    let(:repo_name) { "some-repo" }
    let(:branch) { "some-branch" }

    subject { described_class.new(logger, runner, @repos_path, repo_name, branch) }

    around do |example|
      Dir.mktmpdir("repos_path") do |release_repo|
        @repos_path = release_repo
        example.call
      end
    end

    def repo_path
      File.join(@repos_path, repo_name)
    end

    def release_index_path
      File.join(repo_path, "releases", "index.yml")
    end

    before do
      FileUtils.mkdir_p(File.dirname(release_index_path))

      File.open(release_index_path, "w") do |io|
        io.write <<EOF
---
builds:
  abc:
    version: 123
  xyz:
    version: 125
  def:
    version: 124
EOF
      end
    end

    describe "#promote_final_release" do
      it "logs the important steps" do
        subject.promote_final_release("deployed-to-prod")

        expect(logger).to have_logged(/creating release blobs commit for v125/)
        expect(logger).to have_logged(/creating and pushing tag v125/)
        expect(logger).to have_logged(/merging release v125 into master/)
        expect(logger).to have_logged(/promoting final release to deployed-to-prod/)
      end

      it "commits .final_builds/ and releases/" do
        subject.promote_final_release("deployed-to-prod")

        expect(runner).to have_executed_serially(
          "cd #{repo_path} && git add .final_builds/ releases/",
          "cd #{repo_path} && git commit -m 'add blobs for release v125'",
        )
      end

      it "creates a tag of the latest release and pushes it, after committing" do
        subject.promote_final_release("deployed-to-prod")

        expect(runner).to have_executed_serially(
          /git commit.*add blobs/,
          "cd #{repo_path} && git tag v125",
          "cd #{repo_path} && git push --tags"
        )
      end

      it "pushes HEAD to the remote branch" do
        subject.promote_final_release("deployed-to-prod")

        expect(runner).to have_executed_serially(
          "cd #{repo_path} && git push origin HEAD:refs/heads/deployed-to-prod"
        )
      end

      it "merges the release tag into master after creating and promoting it" do
        # git checkout will update the release index;
        # ensure the tag to merge isn't determined by it after the checkout
        runner.when_running(/git checkout/) do
          File.open(release_index_path, "w") do |io|
            io.write <<EOF
---
builds:
  abc:
    version: 123
  def:
    version: 124
EOF
          end
        end

        subject.promote_final_release("deployed-to-prod")

        expect(runner).to have_executed_serially(
          /git tag v125/,
          /git push .*deployed-to-prod/,
          "cd #{repo_path} && git branch -D master",
          "cd #{repo_path} && git fetch",
          "cd #{repo_path} && git branch --track origin/master master",
          "cd #{repo_path} && git checkout master",
          "cd #{repo_path} && git merge v125",
          "cd #{repo_path} && git push origin master",
        )
      end
    end

    describe "#promote_dev_release" do
      it "logs that it's promoting a dev release" do
        subject.promote_dev_release("staging-deployed")

        expect(logger).to have_logged(/promoting dev release to staging-deployed/)
      end

      it "pushes HEAD to the remote branch" do
        subject.promote_dev_release("staging-deployed")

        expect(runner).to have_executed_serially(
          "cd #{repo_path} && git push origin HEAD:refs/heads/staging-deployed"
        )
      end
    end
  end
end