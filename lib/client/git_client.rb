module DTK::Network::Client
  class GitClient
    module Dtk_Server
      GIT_REMOTE   = 'dtk-server'
    end

    # opts can have keys
    #   :branch
    # returns object of type DTK::Client::GitRepo
    def self.create_empty_git_repo?(repo_dir, opts = {})
      git_repo.new(repo_dir, :branch => opts[:branch])
    end

    # returns head_sha
    def self.empty_commit(repo, commit_msg = nil)
      repo.empty_commit(commit_msg)
      repo.head_commit_sha
    end

    def self.add_remote(repo, remote_name, remote_url)
      repo.add_remote(remote_name, remote_url)
      remote_name
    end

    def self.fetch(repo, remote_name)
      repo.fetch(remote_name)
    end
    
    # opts can have keys
    #   :no_commit
    def self.merge(repo, merge_from_ref, opts = {})
      base_sha = repo.head_commit_sha
      repo.merge(merge_from_ref, :use_theirs => opts[:use_theirs])
      # the git gem does not take no_commit as merge argument; so doing it with soft reset
      repo.reset_soft(base_sha) if opts[:no_commit]
      repo.head_commit_sha
    end

    def self.local_ahead?(repo, merge_from_ref, opts = {})
      base_sha = repo.head_commit_sha
      remote_branch = repo.all_branches.remote.find { |r| "#{r.remote}/#{r.name}" == merge_from_ref }
      remote_sha = remote_branch.gcommit.sha
      repo.local_ahead(base_sha, remote_sha)
    end

    # opts can have keys:
    #   :commit_msg
    # returns head_sha
    def self.stage_and_commit(repo_dir,local_branch_type, opts = {})
      local_branch = branch_from_local_branch_type(local_branch_type)
      repo = create_empty_git_repo?(repo_dir, :branch => local_branch)
      repo.stage_and_commit(opts[:commit_msg])
      repo.head_commit_sha
    end
    
    # TODO: DTK-2765: see what this does and subsume by create_add_remote_and_push
    # For this and other methods in Internal that use Dtk_Server::GIT_REMOTE
    # put a version in Internal taht takes remote_name as param and then have 
    # method with same name in Dtk, that calss this with appropriate remote name
    def self.init_and_push_from_existing_repo(repo_dir, repo_url, remote_branch)
      repo = git_repo.new(repo_dir)
      
      if repo.is_there_remote?(Dtk_Server::GIT_REMOTE)
        push_when_there_is_dtk_remote(repo, repo_dir, repo_url, remote_branch)
      else
        add_remote_and_push(repo, repo_url, remote_branch)
      end
      
      repo.head_commit_sha
    end
    
    def self.pull_from_remote(args)
      repo_url       = args.required(:repo_url)
      remote_branch  = args.required(:branch)
      repo_dir       = args.required(:repo_dir)
      
      repo = git_repo.new(repo_dir, :branch => remote_branch)
      repo.pull(repo.remotes.first, remote_branch)
    end

    def self.push_when_there_is_dtk_remote(repo, repo_dir, repo_url, remote_branch)
      # if there is only one remote and it is dtk-server; remove .git and initialize and push as new repo to dtk-server remote
      # else if multiple remotes and dtk-server being one of them; remove dtk-server; add new dtk-server remote and push
      if repo.remotes.size == 1
        git_repo.unlink_local_clone?(repo_dir)
        create_repo_from_remote_and_push(repo_dir, repo_url, remote_branch)
      else
        repo.remove_remote(Dtk_Server::GIT_REMOTE)
        add_remote_and_push(repo, repo_url, remote_branch)
      end
    end

    def self.create_repo_from_server_remote(repo_dir, repo_url, remote_branch)
      repo = git_repo.new(repo_dir, :branch => Dtkn::LOCAL_BRANCH)
      repo.checkout(Dtkn::LOCAL_BRANCH, :new_branch => true)
      repo.add_remote(Dtk_Server::GIT_REMOTE, repo_url)
      repo
    end

    def self.create_repo_from_remote_and_push(repo_dir, repo_url, remote_branch)
      repo = create_repo_from_server_remote(repo_dir, repo_url, remote_branch)
      # repo = git_repo.new(repo_dir, :branch => Dtkn::LOCAL_BRANCH)
      # repo.checkout(Dtkn::LOCAL_BRANCH, :new_branch => true)
      # repo.add_remote(Dtk_Server::GIT_REMOTE, repo_url)
      repo.stage_and_commit
      repo.push(Dtk_Server::GIT_REMOTE, remote_branch, { :force => true })
      repo.head_commit_sha
    end
    
    def self.add_remote_and_push(repo, repo_url, remote_branch)
      repo.add_remote(Dtk_Server::GIT_REMOTE, repo_url)
      repo.stage_and_commit
      repo.push(Dtk_Server::GIT_REMOTE, remote_branch, { :force => true })
    end

    def self.all_branches(args)
      repo_url = args.required(:path)
      repo = git_repo.new(repo_url)
      repo.all_branches
    end

    def self.current_branch(args)
      repo_url = args.required(:path)
      repo = git_repo.new(repo_url)
      repo.current_branch.name
    end

    def self.git_repo
      ::GitRepo
    end

    def self.reset_hard(repo, merge_from_ref)
      repo.reset_hard(merge_from_ref)
      repo.head_commit_sha
    end

  end
end

