require 'semverly'

module DTK::Network
  module Client
    class DependencyTree
      require_relative('dependency_tree/activated')
      require_relative('dependency_tree/cache')

      include RestWrapper
      extend RestWrapper

      LOCK_FILE = "module_ref.lock"

      def initialize(module_ref, opts = {})
        @module_ref       = module_ref
        @module_directory = opts[:module_directory] || module_ref.repo_dir
        @activated        = Activated.new
        @cache            = Cache.new
        @opts             = opts
        @parsed_module    = opts[:parsed_module]
      end

      def self.get_dependency_tree(module_ref, opts = {})
        if content = FileHelper.get_content?("#{module_ref.repo_dir}/#{LOCK_FILE}")
          ret_as_module_refs(YAML.load(content))
        else
          ret_as_module_refs(compute_and_save(module_ref, opts))
        end
      end

      def self.compute_and_save(module_ref, opts = {})
        activated = compute(module_ref, opts)
        ModuleDir.create_file_with_content("#{module_ref.repo_dir}/#{LOCK_FILE}", YAML.dump(activated.to_h))
        activated
      end

      def self.compute(module_ref, opts = {})
        new(module_ref, opts).compute
      end

      def compute
        dtkn_dependencies = ret_dependencies

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

          dtkn_versions_w_deps_hash = dtkn_versions_with_dependencies(dependency)['versions_w_deps']
          dtkn_versions_w_deps      = dtkn_versions_w_deps_hash.map { |v| v['version'] }

          version_obj       = dependency.version
          versions_in_range = version_obj.versions_in_range(dtkn_versions_w_deps)

          raise "No version matching requirements" if versions_in_range.empty?

          latest_version = versions_in_range.sort.last
          matching_version_dep = ModuleRef::Dependency.new({ name: dependency.name, namespace: dependency.namespace, version: latest_version })

          @activated.add!(matching_version_dep)

          dtkn_deps_of_deps = dtkn_versions_w_deps_hash.find {|dep| dep['version'].eql?(latest_version) }
          dtkn_deps_of_deps_objs = (dtkn_deps_of_deps['dependencies'] || {}).map do |dtkn_dep|
            ModuleRef::Dependency.new({ name: dtkn_dep['module'], namespace: dtkn_dep['namespace'], version: dtkn_dep['version'] })
          end

          activate_dependencies(dtkn_deps_of_deps_objs, opts)
        end
      end

      def ret_dependencies
        if @parsed_module
          ret = { 'dependencies' => [] }
          (@parsed_module.val(:DependentModules) || []).map do |parsed_mr|
            ret['dependencies'] << { 'namespace' => parsed_mr.req(:Namespace), 'module' => parsed_mr.req(:ModuleName), 'version' => parsed_mr.val(:ModuleVersion) }
          end
          ret
        else
          rest_get('modules/dependencies_for_name', { name: @module_ref.name, namespace: @module_ref.namespace, version: @module_ref.version })
        end
      end

      def dtkn_versions_with_dependencies(module_ref)
        rest_get("modules/get_versions_with_dependencies", { name: module_ref.name, namespace: module_ref.namespace })
      end

      def self.ret_as_module_refs(dep_modules)
        dep_modules.map { |k,v| create_module_ref(k, v) }
      end

      def self.create_module_ref(full_name, version_hash)
        namespace, name = full_name.split('/')
        ModuleRef.new({ namespace: namespace, name: name, version: version_hash[:version] })
      end

    end
  end
end