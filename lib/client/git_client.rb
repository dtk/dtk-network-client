module DTK::Network
  module Client
    class GitClient
      require_relative('git_adapter/git_gem')

      # opts can have keys
      #  :branch
      def initialize(repo_dir, opts = {})
        @repo_dir    = repo_dir
        @git_adapter = git_adapter_class.new(repo_dir, opts)
      end

      attr_reader :repo_dir

      def self.clone(repo_url, target_path, branch)
        git_adapter_class.clone(repo_url, target_path, branch)
      end

      def self.is_git_repo?(dir)
        File.directory?("#{dir}/.git")
      end

      def add_remote(name, url)
        @git_adapter.add_remote(name, url)
      end

      def changed?
        @git_adapter.changed?
      end

      # opts can have keys
      #  :new_branch - Boolean
      def checkout(branch, opts = {})
        @git_adapter.checkout(branch, opts)
      end

      def current_branch
        @git_adapter.current_branch
      end

      def diff
        @git_adapter.diff
      end

      def diff_name_status(branch_or_sha_1 = nil, branch_or_sha_2 = nil, opts = {})
        @git_adapter.diff_name_status(branch_or_sha_1, branch_or_sha_2, opts)
      end

      def fetch(remote = 'origin')
        @git_adapter.fetch(remote)
      end

      def head_commit_sha
        @git_adapter.head_commit_sha
      end

      def is_there_remote?(remote_name)
        @git_adapter.is_there_remote?(remote_name)
      end

      def merge(branch_to_merge_from, opts = {})
        @git_adapter.merge(branch_to_merge_from, opts)
      end

      def push(remote, branch, opts = {})
        @git_adapter.push(remote, branch, opts)
      end

      def push_from_cached_branch(remote, branch, opts = {})
        @git_adapter.push_from_cached_branch(remote, branch, opts)
      end

      def pull(remote, branch)
        @git_adapter.pull(remote, branch)
      end

      def remotes
        @git_adapter.remotes
      end

      def remove_remote(name)
        @git_adapter.remove_remote(name)
      end

      def stage_and_commit(commit_msg = nil)
        @git_adapter.stage_and_commit(commit_msg)
      end

      def empty_commit(commit_msg = nil)
        @git_adapter.empty_commit(commit_msg)
      end

      def commit(commit_msg = "", opts = {})
        @git_adapter.commit(commit_msg, opts)
      end

      def reset_soft(sha)
        @git_adapter.reset_soft(sha)
      end

      def reset_hard(sha)
        @git_adapter.reset_hard(sha)
      end

      def revparse(string)
        @git_adapter.revparse(string)
      end

      def rev_list(base_sha)
        @git_adapter.rev_list(base_sha)
      end

      def local_ahead(base_sha, remote_sha)
        @git_adapter.local_ahead(base_sha, remote_sha)
      end

      def add_all
        @git_adapter.add_all
      end

      def all_branches
        @git_adapter.all_branches
      end

      private

      def git_adapter_class
        self.class.git_adapter_class
      end

      def self.git_adapter_class
        GitGem
      end
    end
  end
end
