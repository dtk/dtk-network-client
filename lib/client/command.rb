module DTK::Network
  module Client
    class Command
      require_relative('command/install')
      require_relative('command/publish')

      include RestWrapper
      extend RestWrapper
    end
  end
end