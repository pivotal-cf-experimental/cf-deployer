require 'cf_deployer/repo'

module CfDeployer
  class ReleaseRepo < Repo
    def promote_final_release(branch)
      latest_release = current_final_release

      log_message "creating release blobs commit for v#{latest_release}"
      commit_final_release(latest_release)

      log_message "creating and pushing tag v#{latest_release}"
      push_latest_final_release_tag(latest_release)

      log_message "promoting final release to #{branch}"
      promote(branch)

      log_message "merging release v#{latest_release} into master"
      merge_latest_final_release_into_master(latest_release)
    end

    def promote_dev_release(branch)
      log_message "promoting dev release to #{branch}"
      promote(branch)
    end

    private

    def commit_final_release(release)
      run_git! 'add .final_builds/ releases/'
      run_git! "commit -m 'add blobs for release v#{release}'"
    end

    def push_latest_final_release_tag(release)
      run_git! "tag -f v#{release}"
      run_git! 'push --tags'
    end

    def promote(branch)
      run_git! "push origin HEAD:refs/heads/#{branch}"
    end

    def merge_latest_final_release_into_master(release)
      run_git! 'branch -D master' # ensure a clean slate (i.e. submodule changes)
      run_git! 'fetch'
      run_git! 'branch --track master origin/master'
      run_git! 'checkout master'
      run_git! "merge v#{release}"
      run_git! 'push origin master'
    end

    def current_final_release
      releases_index = YAML.load_file(File.join(path, 'releases', 'index.yml'))

      latest_version = 0

      releases_index['builds'].each do |_, release|
        version = release['version']

        if version > latest_version
          latest_version = version
        end
      end

      latest_version
    end
  end
end
