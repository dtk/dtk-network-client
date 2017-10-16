module DTK::Network
  module Client
    class DependencyTree
      def initialize(module_ref)
        @module_ref = module_ref
        @activated  = Activated.new
      end

      def self.compute
        # fetch base module info with dependencies from remote
        # name: 'wordpress',
        # namespace: 'dtk-examples',
        # version: '1.0.0'
        # send request to repoman instead of line bellow
        base_module_with_deps_info = ModuleMock.ret(@module_ref)


        dependencies = base_module_with_deps_info[:dependencies]
        # iterate through dependencies
        dependencies.each do |dependency|
          # for every dependency with requirements send request to repoman route wich takes version range requirements and return matching versions
          dep_module_matching_versions = ModuleMock.versions(dependency)

          # check if any of those versions is already activated
          activated = @activated.contains_module?(dep_module_matching_versions)

          # if some of the versions is already activated then skip to next dependency
          next if activated

          # if same module activated but version does not match then deactivate module version and try with different one
          @activated.delete?(dep_module_matching_versions[:name], dep_module_matching_versions[:namespace])

          # if matching versions are not activated send request with latest version to repoman route which takes module version and return dep_module info and dependencies
          dep_module_with_deps_info = ModuleMock.ret(dependency)

          # take latest version and activate it
          @activated.add?(dep_module_with_deps_info)

          # iterate through dependencies of dependencies and repeat the same process
          dep_dependencies = dep_module_with_deps_info[:dependencies]
          dep_dependencies.each do |dep_dependency|
            # repeat above (recursion)
          end
        end

        # ret module info and dependencies from dtk network
        # raise if errors
        # unless errors execute dependency calculations
        # when dependency calculations done write module_ref.lock file
        # read and parse module_refs.lock and install module
      end
    end
  end
end