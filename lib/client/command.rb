module DTK::Network
  module Client
    class Command
      require_relative('command/install')
      require_relative('command/publish')

      include RestWrapper
      extend RestWrapper

      def self.wrap_command(args = Args.new, &block)
        block.call(Args.convert(args))
      end
    end
  end
end