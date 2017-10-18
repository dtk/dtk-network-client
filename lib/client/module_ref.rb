module DTK::Network
  module Client
    class ModuleRef
      def initialize(module_info)
        @name         = module_info[:name]
        @namespace    = module_info[:namespace]
        @version      = module_info[:version]
        @dependencies = module_info[:dependencies]
      end
    end
  end
end

