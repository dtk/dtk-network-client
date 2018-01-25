module DTK::Network::Client
  class ModuleRef
    class Dependency
      class Remote < self
        def initialize(module_info)
          super(name: module_info[:name] || module_info['module'], namespace: module_info[:namespace] || module_info['namespace'])
          version_str = module_info[:version]||module_info['version']
          @version    = ModuleRef::Version.new(version_str)
        end

        def dtkn_versions_with_dependencies
          response = rest_get("modules/get_versions_with_dependencies", { name: self.name, namespace: self.namespace })
          response['versions']
        end
      end
    end
  end
end