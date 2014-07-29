require 'fileutils'
require 'tmpdir'
require 'yaml'

require 'spec_helper'
require 'cf_deployer/repo'

module CfDeployer
  describe Repo do
    let(:logger) { FakeLogger.new }
    let(:runner) { FakeCommandRunner.new }
    let(:uri) { 'git@github.com:cloudfoundry/some-repo.git' }
    let(:ref) { 'some-ref' }

    subject { described_class.new(logger, runner, @repos_path, uri, ref) }

    around do |example|
      Dir.mktmpdir('repos_path') do |release_repo|
        @repos_path = Pathname.new(release_repo).realpath
        example.call
      end
    end

    def repo_name
      uri[/([^\.:\/]+)(\.git)?$/, 1]
    end

    def repo_path
      File.join(@repos_path, repo_name)
    end

    describe '#sync!' do
      before do
        ShellOut.unstub(:capture_output)
      end

      before do
        runner.when_running(/git clone/) do
          Dir.mkdir(repo_path)
          Dir.chdir(repo_path) do
            `git init`
          end
        end
      end

      it 'cleans the repository and fetches the latest from origin on the ref' do
        subject.sync!

        expect(runner).to have_executed_serially(
                              "rm -rf #{repo_path}",
                              "mkdir -p #{repo_path}",
                              "git clone --branch some-ref git@github.com:cloudfoundry/some-repo.git #{repo_path}",
                              "cd #{repo_path} && git clean --force --force -d",
                              "cd #{repo_path} && git submodule sync --recursive",
                              "cd #{repo_path} && git submodule init",
                              "cd #{repo_path} && git submodule status | awk '{print $2}' | xargs -P10 -n1 git submodule update --init --recursive",
                              "cd #{repo_path} && git submodule foreach --recursive git clean --force --force -d"
                          )
      end

      it "logs that it's syncing" do
        subject.sync!
        expect(logger).to have_logged('cloudfoundry/some-repo: syncing with some-ref')
      end

      context 'with a http uri' do
        let(:uri) { 'https://github.com/cloudfoundry/some-repo.git' }

        it 'logs the proper owner/repo name' do
          subject.sync!
          expect(logger).to have_logged('cloudfoundry/some-repo: syncing with some-ref')
        end
      end
    end

    describe '#use_local_blob_cache' do
      before do
        ShellOut.unstub(:capture_output)
      end
      it 'symlinks .blobs to the specified directory' do
        subject.use_local_blob_cache('my_dir')

        expect(runner).to have_executed_serially(
                              "rm -rf #{repo_path}/.blobs",
                              "mkdir -p my_dir",
                              "ln -s my_dir #{repo_path}/.blobs"
                          )
      end
    end


    describe '#path' do
      context 'with a ssh git uri' do
        let(:uri) { 'git@github.com:foo/some-repo.git' }

        its(:path) { should == "#{@repos_path}/some-repo" }
      end

      context 'with a https git uri' do
        let(:uri) { 'https://github.com/foo/some-repo.git' }

        its(:path) { should == "#{@repos_path}/some-repo" }
      end

      context 'with a local path' do
        let(:uri) { Dir.mktmpdir }

        its(:path) { should == uri }
      end
    end
  end
end
