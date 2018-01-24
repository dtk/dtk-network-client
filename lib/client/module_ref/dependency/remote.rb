module DTK::Network::Client
  class ModuleRef
    class Dependency
      class Remote < self
        def initialize(module_info)
          super(name: module_info['module'], namespace: module_info['namespace'])
          version_str = module_info[:version]||module_info['version']
          @version    = ModuleRef::Version.new(version_str)
        end
      end
    end
  end
end