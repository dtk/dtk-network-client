module DTK::Network
  module Client
    class DependencyTree
      require_relative('dependency_tree/activated')
      require_relative('module_mock')

      def initialize(module_ref)
        @module_ref = module_ref
        @activated  = Activated.new
      end

      def compute
        base_module_with_deps_info = ModuleMock.ret(@module_ref)


        dependencies = base_module_with_deps_info[:dependencies]
        activate_dependencies(dependencies)

        # ret module info and dependencies from dtk network
        # raise if errors
        # unless errors execute dependency calculations
        # when dependency calculations done write module_ref.lock file
        # read and parse module_refs.lock and install module
        @activated
      end

      def activate_dependencies(dependencies, opts = {})
        dependencies.each do |dependency|
          # for every dependency with requirements send request to repoman route wich takes version range requirements and return matching versions
          dep_module_matching_versions = ModuleMock.versions(dependency)

          # check if any of those versions is already activated
          activated = @activated.contains_module?(dep_module_matching_versions)

          # if some of the versions is already activated then skip to next dependency
          next if activated

          # if same module activated but version does not match then deactivate module version and try with different one
          # @activated.deactivate?(dep_module_matching_versions[:name], dep_module_matching_versions[:namespace])
          if existing_name = @activated.existing_name(dep_module_matching_versions[:name])
            throw :test
          end

          versions_activated = []
          if versions = dep_module_matching_versions[:versions]
            versions = versions.sort.reverse
            versions.each do |version|
              next if versions_activated.include?(dep_module_matching_versions[:name])
              catch :test do
                latest_version = {
                  name: dep_module_matching_versions[:name],
                  namespace: dep_module_matching_versions[:namespace],
                  version: version
                }
                @activated.add(latest_version)

                # if matching versions are not activated send request with latest version to repoman route which takes module version and return dep_module info and dependencies
                dep_module_with_deps_info = ModuleMock.ret(latest_version)

                # iterate through dependencies of dependencies and repeat the same process
                dep_dependencies = dep_module_with_deps_info[:dependencies]
                unless dep_dependencies.empty?
                  activate_dependencies(dep_dependencies, parent: dep_module_with_deps_info)
                  versions_activated << dep_module_matching_versions[:name]
                end
              end
            end
          end
          # unless activated, choose latest version
          # latest_version = select_latest(dep_module_matching_versions)
          # @activated.add(latest_version)


          # # if matching versions are not activated send request with latest version to repoman route which takes module version and return dep_module info and dependencies
          # dep_module_with_deps_info = ModuleMock.ret(latest_version)

          # # iterate through dependencies of dependencies and repeat the same process
          # dep_dependencies = dep_module_with_deps_info[:dependencies]
          # unless dep_dependencies.empty?
          #   activate_dependencies(dep_dependencies, parent: dep_module_with_deps_info)
          # end
        end
      end

      def select_latest(dep_module_matching_versions)
        if versions = dep_module_matching_versions[:versions]
          sorted_versions = versions.sort
          latest_version = sorted_versions.delete(sorted_versions.last)
          {
            name: dep_module_matching_versions[:name],
            namespace: dep_module_matching_versions[:namespace],
            version: latest_version
          }
        end
      end
    end
  end
end