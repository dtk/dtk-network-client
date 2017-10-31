module DTK::Network::Client
  class ModuleRef
    class Dependency
      attr_reader :name, :namespace, :version, :full_name

      def initialize(module_info)
        @name      = module_info[:name]
        @namespace = module_info[:namespace]
        @version   = ModuleRef::Version.new(module_info[:version])
        @full_name = "#{@namespace}/#{@name}"
      end
    end
  end
end

