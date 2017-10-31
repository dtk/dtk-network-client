require 'dtk_common_core'
require 'rest-client'

module DTK
  module Network
    module Client
      require_relative('client/config')
      require_relative('client/git_repo')
      require_relative('client/git_client')
      require_relative('client/install')
      require_relative('client/publish')
      require_relative('client/dependency_tree')
      require_relative('client/conn')
      require_relative('client/session')
      require_relative('client/args')
      require_relative('client/module_ref')
      require_relative('client/module_dir')
    end
  end
end