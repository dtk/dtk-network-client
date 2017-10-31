require 'semverly'

module DTK::Network
  module Client
    class DependencyTree
      require_relative('dependency_tree/activated')
      require_relative('dependency_tree/cache')

      def initialize(module_ref, opts = {})
        @module_ref       = module_ref
        @module_directory = opts[:module_directory]
        @activated        = Activated.new
        @cache            = Cache.new
        @opts             = opts
      end

      def self.compute_and_save(module_ref, opts = {})
        activated = compute(module_ref, opts)
        ModuleDir.create_file_with_content("#{module_ref.repo_dir}/module_ref.lock", YAML.dump(activated.to_h))
      end

      def self.compute(module_ref, opts = {})
        new(module_ref, opts).compute
      end

      def compute
        dtkn_dependencies = Session.rest_get('modules/dependencies_for_name', { name: @module_ref.name, namespace: @module_ref.namespace, version: @module_ref.version })
        dtkn_dependencies = JSON.parse(dtkn_dependencies)

        dependencies = dtkn_dependencies['dependencies'].map do |pm_ref|
          ModuleRef::Dependency.new({ name: pm_ref['module'], namespace: pm_ref['namespace'], version: pm_ref['version'] })
        end

        activate_dependencies(dependencies)
        @activated
      end

      private

      def activate_dependencies(dependencies, opts = {})
        dependencies.each do |dependency|
          next if @activated.module_activated?(dependency)

          # all_dtkn_dependency_versions  = Session.rest_get("modules/get_versions", { name: dependency.name, namespace: dependency.namespace })
          all_dtkn_dependency_versions  = Session.rest_get("modules/get_versions_with_dependencies", { name: dependency.name, namespace: dependency.namespace })

          dtkn_dependency_versions_hash = JSON.parse(all_dtkn_dependency_versions)
          # dtkn_dependency_versions      = dtkn_dependency_versions_hash['versions']
          dtkn_dependency_versions      = dtkn_dependency_versions_hash.map { |v| v['version'] }

          req_dependency_version_obj          = dependency.version
          dtkn_versions_matching_requirements = req_dependency_version_obj.versions_in_range(dtkn_dependency_versions)

          raise "No version matching requirements" if dtkn_versions_matching_requirements.empty?

          latest_version = dtkn_versions_matching_requirements.sort.last
          dtkn_dependency_matching_version = ModuleRef::Dependency.new({ name: dependency.name, namespace: dependency.namespace, version: latest_version })
          @activated.add!(dtkn_dependency_matching_version)

          # dtkn_deps_of_deps = Session.rest_get("modules/dependencies_for_name", { name: dtkn_dependency_matching_version.name, namespace: dtkn_dependency_matching_version.namespace, version: latest_version })
          dtkn_deps_of_deps = dtkn_dependency_versions_hash.find {|dep| dep['version'].eql?(latest_version) }
          # dtkn_deps_of_deps = JSON.parse(dtkn_deps_of_deps)

          dtkn_deps_of_deps_objs = (dtkn_deps_of_deps['dependencies'] || {}).map do |dtkn_dep_of_dep|
            ModuleRef::Dependency.new({ name: dtkn_dep_of_dep['module'], namespace: dtkn_dep_of_dep['namespace'], version: dtkn_dep_of_dep['version'] })
          end

          activate_dependencies(dtkn_deps_of_deps_objs, opts)
        end
      end

    end
  end
end