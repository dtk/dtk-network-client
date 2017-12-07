module DTK::Network
  module Client
    class Command
      require_relative('command/install')
      require_relative('command/publish')
      require_relative('command/list')

      include RestWrapper
      extend RestWrapper
      include DTK::Network::Client::Util::Tar

      def self.wrap_command(args = Args.new, &block)
        block.call(Args.convert(args))
      end
    end
  end
end