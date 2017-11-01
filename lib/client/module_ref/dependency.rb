module DTK::Network::Client
  class ModuleRef
    class Dependency < self
      def initialize(module_info)
        super
        @version = ModuleRef::Version.new(module_info[:version])
      end
    end
  end
end