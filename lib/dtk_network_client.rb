require 'dtk_common_core'
require 'rest-client'

module DTK
  module Network
    module Client
      require_relative('client/config')
      require_relative('client/git_repo')
      require_relative('client/install')
      require_relative('client/dependency_tree')
      require_relative('client/conn')
      require_relative('client/session')
    end
  end
end