#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'git'

module DTK::Network
  module Client
    class GitGem
      attr_accessor :git_repo

      # Monkey patch the git merge method
      # to allow passing the --allow-unrelated-histories flag
      # more info: http://stackoverflow.com/questions/37937984/git-refusing-to-merge-unrelated-histories
      class ::Git::Base
        def merge(branch, message = 'merge', opts = {})
          self.lib.merge(branch, message, opts)
        end

        def rev_list(sha)
          self.lib.rev_list(sha)
        end

        def name_status(branch1 = nil, branch2 = nil, opts = {})
          self.lib.name_status(branch1, branch2, opts)
        end
      end

      class ::Git::Lib
        def merge(branch, message = nil, opts = {})
          arr_opts = []
          arr_opts << '--allow-unrelated-histories' if opts[:allow_unrelated_histories]
          arr_opts << '-Xtheirs' if opts[:use_theirs]
          arr_opts << '-m' << message if message
          arr_opts += [branch]
          command('merge', arr_opts)
        end

        def rev_list(sha)
          arr_opts = [sha]
          command('rev-list', arr_opts)
        end

        def name_status(branch1 = nil, branch2 = nil, opts = {})
          arr_opts = []
          arr_opts << '--name-status'
          arr_opts << "--diff-filter=#{opts[:diff_filter]}" if opts[:diff_filter]
          arr_opts << branch1 if branch1
          arr_opts << branch2 if branch2

          command_lines('diff', arr_opts).inject({}) do |memo, line|
            status, path = line.split("\t")
            memo[path] = status
            memo
          end
        end

        def command_lines(cmd, opts = [], chdir = true, redirect = '')
          cmd_op = command(cmd, opts, chdir)
          op = cmd_op.encode("UTF-8", "binary", {
                :invalid => :replace,
                :undef => :replace
              })
          op.split("\n")
        end
      end
      
      # opts can have keys
      #  :branch
      def initialize(repo_dir, opts = {})
        @repo_dir = repo_dir
        @git_repo = ::Git.init(repo_dir)
        # If we want to log Git interaction
        # @git_repo = ::Git.init(repo_dir, :log => Logger.new(STDOUT))
        @local_branch_name = opts[:branch]
      end

      def self.clone(repo_url, target_path, branch)
        git_base = handle_git_error { ::Git.clone(repo_url, target_path) }
        begin
          git_base.checkout(branch)
        rescue => e
          # TODO: see if any other kind of error
          raise "The branch or tag '#{branch}' does not exist on repo '#{repo_url}'"
        end
        git_base
      end

      # opts can have keys
      #  :new_branch - Boolean
      def checkout(branch, opts = {})
        ret = @git_repo.checkout(branch, opts)
        @local_branch_name = branch
        ret
      end

      def fetch(remote = 'origin')
        @git_repo.fetch(remote)
      end

      def add_remote(name, url)
        @git_repo.remove_remote(name) if is_there_remote?(name)
        @git_repo.add_remote(name, url)
      end

      def remove_remote(name)
        @git_repo.remove_remote(name) if is_there_remote?(name)
      end

      def push(remote, branch, opts = {})
        branch_name = current_branch ? current_branch.name : 'master'
        branch_for_push = "#{branch_name}:refs/heads/#{branch || local_branch_name}"
        @git_repo.push(remote, branch_for_push, opts)
      end

      def push_from_cached_branch(remote, branch, opts = {})
        branch_for_push = "HEAD:#{branch}"
        @git_repo.push(remote, branch_for_push, opts)
      end

      def merge(branch_to_merge_from, opts = {})
        @git_repo.merge(branch_to_merge_from, 'merge', :allow_unrelated_histories => allow_unrelated_histories?, :use_theirs => opts[:use_theirs])
      end

      def status
        @git_repo.status
      end

      def changed
        status.is_a?(Hash) ? status.changed().keys : status.changed().collect { |file| file.first }
      end

      def untracked
        status.is_a?(Hash) ? status.untracked().keys : status.untracked().collect { |file| file.first }
      end

      def deleted
        status.is_a?(Hash) ? status.deleted().keys : status.deleted().collect { |file| file.first }
      end

      def added
        status.is_a?(Hash) ? status.added().keys : status.added().collect { |file| file.first }
      end

      def stage_and_commit(commit_msg = nil)
        commit_msg ||= default_commit_message
        add_all
        begin
          commit(commit_msg)
        rescue
          # do not raise if nothing to commit
        end
      end

      def empty_commit(commit_msg = nil)
        commit_msg ||= default_commit_message
        commit(commit_msg, :allow_empty => true)
      end

      def reset_soft(sha)
        @git_repo.reset(sha)
      end

      def reset_hard(sha)
        @git_repo.reset_hard(sha)
      end

      def revparse(sha_or_string)
        @git_repo.revparse(sha_or_string)
      end

      def rev_list(base_sha)
        @git_repo.rev_list(base_sha)
      end

      def local_ahead(base_sha, remote_sha)
        results = @git_repo.rev_list(base_sha)
        !results.split("\n").grep(remote_sha).empty?
      end

      def stage_changes()
        handle_git_error do
          @git_repo.add(untracked())
          @git_repo.add(added())
          @git_repo.add(changed())
        end
        deleted().each do |file|
          begin
            @git_repo.remove(file)
          rescue
            # ignore this error means file has already been staged
            # we cannot support status of file, in 1.8.7 so this is
            # solution for that
          end
        end
      end

      # opts can have keys
      #   :allow_empty
      def commit(commit_msg = "", opts = {})
        @git_repo.commit(commit_msg, :allow_empty => opts[:allow_empty])
      end

      def add(*files)
        @git_repo.add(files.flatten)
      end

      def add_all
        # Cannot use '@git_repo.add(:all => true)' because this only works if pwd is base git repo
        fully_qualified_repo_dir = (@repo_dir =~ /^\// ? @repo_dir : File.join(Dir.pwd, @repo_dir))
        @git_repo.add(fully_qualified_repo_dir, :all => true )
      end

      def is_there_remote?(remote_name)
        @git_repo.remotes.find { |r| r.name == remote_name }
      end

      def current_branch
        @git_repo.branches.local.find { |b| b.current }
      end

      def remotes
        @git_repo.remotes
      end

      def head_commit_sha
        current_branch.gcommit.sha
      end

      def pull(remote, branch)
        @git_repo.pull(remote, branch)
      end

      def diff
        @git_repo.diff
      end

      def diff_name_status(branch_or_sha_1, branch_or_sha_2, opts = {})
        @git_repo.name_status(branch_or_sha_1, branch_or_sha_2, opts)
      end

      def changed?
        (!(changed().empty? && untracked().empty? && deleted().empty?))
      end


      def all_branches
        @git_repo.branches
      end

      private

      def default_commit_message
        "DTK Commit from network client"
      end

    end
  end
end
