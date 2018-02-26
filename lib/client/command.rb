module DTK::Network
  module Client
    class Command
      require_relative('command/install')
      require_relative('command/publish')
      require_relative('command/list')
      require_relative('command/info')
      require_relative('command/push')
      require_relative('command/pull')
      require_relative('command/grant_access')
      require_relative('command/revoke_access')
      require_relative('command/delete')
      require_relative('command/create_namespace')
      require_relative('command/unpublish')
      require_relative('command/update')

      include RestWrapper
      extend RestWrapper
      include DTK::Network::Client::Util::Tar

      def self.wrap_command(args = Args.new, &block)
        block.call(Args.convert(args))
      end
    end
  end
end